-- Local development seed: 12 weekly challenges starting with the current week,
-- so there is always a live challenge after `npx supabase db reset`.
-- Weeks run Monday 00:00 → next Monday 00:00, Europe/London.

with week0 as (
  select (date_trunc('week', now() at time zone 'Europe/London')) as monday
),
quests (n, title, category, description, tips) as (
  values
  (0, 'Bake something you''ve never baked', 'baking',
   'Pick a recipe you''ve never tried, from bread to brownies, and bake it. Show us the result, flops welcome.',
   array['Read the whole recipe before you start', 'Weigh ingredients if you can', 'Film the reveal moment']),
  (1, 'Write a four-line poem', 'poetry',
   'Write a short poem about something you saw this week. Rhyme optional.',
   array['Start with one concrete image', 'Read it out loud before posting']),
  (2, 'Draw your breakfast', 'drawing',
   'Draw, sketch or paint whatever you had for breakfast. Any medium counts.',
   array['Start with light outlines', 'Five minutes is enough']),
  (3, 'Learn eight bars of a song', 'music',
   'Learn eight bars of a song on any instrument, including your voice, and perform them.',
   array['Slow it down first, speed it up later', 'Record a few takes']),
  (4, 'Hold a plank for one minute', 'fitness',
   'Build up to a one-minute plank. Show your best attempt.',
   array['Keep your back straight', 'Practise in short sets during the week']),
  (5, 'Photograph a shadow', 'photography',
   'Take a photo where a shadow is the subject, not the thing casting it.',
   array['Early morning and late afternoon give long shadows', 'Try black and white']),
  (6, 'Learn a magic trick', 'magic',
   'Learn one sleight-of-hand or card trick and perform it on camera.',
   array['Practise in front of a mirror', 'Patter (what you say) sells the trick']),
  (7, 'Fold an origami crane', 'origami',
   'Fold a paper crane from a single square sheet.',
   array['Crisp folds make everything easier', 'Any square paper works']),
  (8, 'Cook a dish from a new cuisine', 'cooking',
   'Cook a dish from a cuisine you''ve never cooked before.',
   array['Pick something with few unfamiliar ingredients', 'Tell us where the recipe is from']),
  (9, 'Learn a phrase in a new language', 'language',
   'Learn to say a full sentence in a language you don''t speak, and say it on camera.',
   array['Listen to a native speaker first', 'Write it down phonetically']),
  (10, 'Learn a short dance', 'dance',
   'Learn and perform 15 seconds of any dance.',
   array['Learn it in four-count chunks', 'Film from the front, full body in frame']),
  (11, 'Write a 100-word story', 'writing',
   'Write a complete story in exactly 100 words.',
   array['Start in the middle of the action', 'Cut adjectives first when trimming'])
)
insert into public.challenges (title, description, category, tips, opens_at, closes_at)
select
  q.title, q.description, q.category, q.tips,
  (w.monday + make_interval(weeks => q.n)) at time zone 'Europe/London',
  (w.monday + make_interval(weeks => q.n + 1)) at time zone 'Europe/London'
from quests q cross join week0 w;
