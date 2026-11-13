// create-upload-url
//
// Hands the app short-lived presigned PUT URLs so it can upload an entry's
// video/photo (and thumbnail) straight to R2. Video bytes never pass through
// Supabase. Checks: signed in, accepted this challenge, window (+1h grace)
// still open, no entry yet, allowed file type, under the size cap.
//
// POST { challenge_id, media_type: "video" | "image", content_type,
//        size_bytes, thumb?: { content_type, size_bytes } }
// 200  { media_key, media_upload_url, thumb_key?, thumb_upload_url?,
//        expires_in }

import { createClient } from 'npm:@supabase/supabase-js@2';
import { corsHeaders, fail, json } from '../_shared/http.ts';
import { r2 } from '../_shared/r2.ts';

const MB = 1024 * 1024;
const URL_TTL_SECONDS = 600; // 10 minutes

const ALLOWED: Record<string, { types: Record<string, string>; maxBytes: number }> = {
  // Mobile compresses to ~5–10 MB; web can't compress, so allow up to 30 MB.
  video: {
    types: { 'video/mp4': 'mp4', 'video/quicktime': 'mov', 'video/webm': 'webm' },
    maxBytes: 30 * MB,
  },
  image: {
    types: { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' },
    maxBytes: 10 * MB,
  },
};
const THUMB = { types: { 'image/jpeg': 'jpg' } as Record<string, string>, maxBytes: 1 * MB };

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type Body = {
  challenge_id?: unknown;
  media_type?: unknown;
  content_type?: unknown;
  size_bytes?: unknown;
  thumb?: { content_type?: unknown; size_bytes?: unknown } | null;
};

function validSize(n: unknown, max: number): n is number {
  return typeof n === 'number' && Number.isInteger(n) && n > 0 && n <= max;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return fail('method_not_allowed', 'Use POST', 405);

  // Who is calling? Use a client scoped to their JWT so RLS applies.
  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '');
  if (!token) return fail('unauthorized', 'Sign in first', 401);

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: `Bearer ${token}` } } },
  );
  const { data: userData, error: userError } = await supabase.auth.getUser(token);
  const user = userData?.user;
  if (userError || !user) return fail('unauthorized', 'Sign in first', 401);

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return fail('bad_request', 'Body must be JSON', 400);
  }

  const { challenge_id, media_type, content_type, size_bytes, thumb } = body;
  if (typeof challenge_id !== 'string' || !UUID_RE.test(challenge_id)) {
    return fail('bad_request', 'challenge_id must be a UUID', 400);
  }
  if (typeof media_type !== 'string' || !(media_type in ALLOWED)) {
    return fail('bad_request', 'media_type must be video or image', 400);
  }
  const rules = ALLOWED[media_type];
  if (typeof content_type !== 'string' || !(content_type in rules.types)) {
    return fail('unsupported_type', `Unsupported ${media_type} type`, 415);
  }
  if (!validSize(size_bytes, rules.maxBytes)) {
    return fail(
      'too_large',
      `${media_type} must be under ${rules.maxBytes / MB} MB`,
      413,
    );
  }
  if (thumb != null) {
    if (typeof thumb.content_type !== 'string' || !(thumb.content_type in THUMB.types)) {
      return fail('unsupported_type', 'Thumbnail must be JPEG', 415);
    }
    if (!validSize(thumb.size_bytes, THUMB.maxBytes)) {
      return fail('too_large', 'Thumbnail must be under 1 MB', 413);
    }
  }

  // Accepted + open (with grace)? Same rule RLS applies on insert.
  const { data: allowed, error: rpcError } = await supabase.rpc('can_submit', {
    uid: user.id,
    cid: challenge_id,
  });
  if (rpcError) return fail('server_error', 'Could not check challenge', 500);
  if (!allowed) {
    return fail(
      'not_allowed',
      'Accept this week\'s quest first, and post before it closes',
      403,
    );
  }

  const { data: existing } = await supabase
    .from('submissions')
    .select('id')
    .eq('user_id', user.id)
    .eq('challenge_id', challenge_id)
    .maybeSingle();
  if (existing) return fail('already_submitted', 'You already posted an entry', 409);

  const prefix = `submissions/${challenge_id}/${user.id}/${crypto.randomUUID()}`;
  const mediaKey = `${prefix}.${rules.types[content_type]}`;
  const storage = r2();

  const response: Record<string, unknown> = {
    media_key: mediaKey,
    media_upload_url: await storage.presignPut(
      mediaKey,
      content_type,
      size_bytes,
      URL_TTL_SECONDS,
    ),
    expires_in: URL_TTL_SECONDS,
  };
  if (thumb != null) {
    const thumbKey = `${prefix}.thumb.jpg`;
    response.thumb_key = thumbKey;
    response.thumb_upload_url = await storage.presignPut(
      thumbKey,
      thumb.content_type as string,
      thumb.size_bytes as number,
      URL_TTL_SECONDS,
    );
  }
  return json(response);
});
