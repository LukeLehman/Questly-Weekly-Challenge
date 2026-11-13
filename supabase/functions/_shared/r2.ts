// Cloudflare R2 (S3-compatible) presigning. Credentials come only from
// Edge Function secrets (local: supabase/functions/.env).
import { AwsClient } from 'npm:aws4fetch@1.0.20';

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing secret ${name}`);
  return value;
}

export function r2() {
  const accountId = requireEnv('R2_ACCOUNT_ID');
  const bucket = requireEnv('R2_BUCKET');
  const client = new AwsClient({
    accessKeyId: requireEnv('R2_ACCESS_KEY_ID'),
    secretAccessKey: requireEnv('R2_SECRET_ACCESS_KEY'),
    service: 's3',
    region: 'auto',
  });
  const base = `https://${accountId}.r2.cloudflarestorage.com/${bucket}`;

  return {
    /**
     * Presigned PUT URL valid for [expiresIn] seconds. Content-Type and
     * Content-Length are signed, so the upload must match both exactly:
     * a client can't swap in a different file type or a bigger file.
     */
    async presignPut(
      key: string,
      contentType: string,
      contentLength: number,
      expiresIn: number,
    ): Promise<string> {
      const url = new URL(`${base}/${encodeKey(key)}`);
      url.searchParams.set('X-Amz-Expires', String(expiresIn));
      const signed = await client.sign(url.toString(), {
        method: 'PUT',
        headers: {
          'content-type': contentType,
          'content-length': String(contentLength),
        },
        aws: { signQuery: true, allHeaders: true },
      });
      return signed.url;
    },
  };
}

function encodeKey(key: string): string {
  return key.split('/').map(encodeURIComponent).join('/');
}
