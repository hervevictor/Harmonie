-- ============================================================================
-- HARMONIE - SYSTEM DATABASE INITIALIZATION & MIGRATIONS SCRIPT
-- ============================================================================
-- This script provisions all the required tables, seed data, storage buckets, 
-- and RLS (Row Level Security) policies for the Harmonie application in Supabase.
-- 
-- How to run this:
-- 1. Go to your Supabase Dashboard (https://supabase.com/dashboard)
-- 2. Select your project "harmonie"
-- 3. Click on the "SQL Editor" tab in the left sidebar
-- 4. Click "New Query"
-- 5. Copy the entire contents of this file and paste it in the SQL Editor
-- 6. Click "Run" (or Ctrl + Enter / Cmd + Enter)
-- ============================================================================

-- Enable the UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. BASE TABLES DEFINITION
-- ============================================================

-- Table public.profiles (should match auth.users linked structure)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  full_name text,
  avatar_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Table public.plans (SaaS/Pricing plans)
CREATE TABLE IF NOT EXISTS public.plans (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  name text NOT NULL UNIQUE,
  max_file_size_mb integer DEFAULT 10,
  can_upload_video boolean DEFAULT false,
  can_upload_pdf boolean DEFAULT false,
  max_uploads_per_month integer DEFAULT 10,
  price numeric DEFAULT 0.00,
  created_at timestamp with time zone DEFAULT now()
);

-- Ensure profiles table has the relation to plans
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS current_plan_id uuid REFERENCES public.plans(id) ON DELETE SET NULL;

-- Table public.instruments (Seed data mapping to Flutter instrument model)
CREATE TABLE IF NOT EXISTS public.instruments (
  id text NOT NULL PRIMARY KEY, -- Text-based ID like 'piano', 'guitar_acoustic' for flutter parity
  name text NOT NULL,
  emoji text,
  family text,
  difficulty integer CHECK (difficulty BETWEEN 1 AND 5),
  soundfont_id text,
  created_at timestamp with time zone DEFAULT now()
);

-- Ensure existing tables use TEXT for instrument_id to remain fully compatible with Flutter models
-- Table public.sessions (User uploaded recording sessions/history)
CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  instrument_id text REFERENCES public.instruments(id) ON DELETE SET NULL,
  file_url text,
  file_type text,
  key_signature text,
  bpm numeric,
  chords jsonb,
  notes jsonb,
  audio_result_url text,
  job_id text,
  created_at timestamp with time zone DEFAULT now()
);

-- Table public.user_instruments (Favorites chosen by user)
CREATE TABLE IF NOT EXISTS public.user_instruments (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  instrument_id text NOT NULL REFERENCES public.instruments(id) ON DELETE CASCADE,
  created_at timestamp with time zone DEFAULT now(),
  PRIMARY KEY (user_id, instrument_id)
);

-- Table public.files (User files tracking)
CREATE TABLE IF NOT EXISTS public.files (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  original_name text NOT NULL,
  storage_path text NOT NULL,
  file_type text NOT NULL, -- 'audio', 'video', 'image', 'pdf'
  mime_type text,
  size_bytes bigint,
  status text DEFAULT 'ready',
  uploaded_at timestamp with time zone DEFAULT now()
);

-- Table public.analyses (AI Analysis runs on files)
CREATE TABLE IF NOT EXISTS public.analyses (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  file_id uuid NOT NULL REFERENCES public.files(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  instrument_id text REFERENCES public.instruments(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'error'
  detected_key text,
  time_signature text,
  tempo_bpm numeric,
  notes_sequence jsonb,
  chords_sequence jsonb,
  midi_storage_path text,
  processing_time_ms integer,
  error_message text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Table public.subscriptions (User active plan subscriptions)
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_id uuid NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Table public.playbacks (User playback history/events)
CREATE TABLE IF NOT EXISTS public.playbacks (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  analysis_id uuid REFERENCES public.analyses(id) ON DELETE SET NULL,
  instrument_id text REFERENCES public.instruments(id) ON DELETE SET NULL,
  played_at timestamp with time zone DEFAULT now()
);

-- Table public.usage_logs (Telemetry/Usage monitoring)
CREATE TABLE IF NOT EXISTS public.usage_logs (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action text NOT NULL,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now()
);

-- ============================================================
-- 2. PEDAGOGICAL & INTERACTIVE TABLES (MIGRATION 002)
-- ============================================================

-- Table public.quiz_results : quiz results history
CREATE TABLE IF NOT EXISTS public.quiz_results (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  analysis_id uuid REFERENCES public.analyses(id) ON DELETE SET NULL,
  instrument_id text REFERENCES public.instruments(id) ON DELETE SET NULL,
  topic text NOT NULL,
  level text NOT NULL CHECK (level IN ('débutant', 'intermédiaire', 'avancé')),
  score integer NOT NULL CHECK (score >= 0),
  total_questions integer NOT NULL CHECK (total_questions > 0),
  answers jsonb,                   -- Details of each answer
  duration_seconds integer,        -- Time taken
  created_at timestamp with time zone DEFAULT now()
);

-- Table public.courses_progress : user learning path progression
CREATE TABLE IF NOT EXISTS public.courses_progress (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  instrument_id text REFERENCES public.instruments(id) ON DELETE SET NULL,
  topic text NOT NULL,
  level text NOT NULL,
  course_data jsonb,               -- Full course generated markdown/content
  completed boolean DEFAULT false,
  completion_percentage integer DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),
  last_accessed_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT courses_progress_unique UNIQUE (user_id, instrument_id, topic, level)
);

-- Table public.generated_scores : transposed sheets/partitions generated
CREATE TABLE IF NOT EXISTS public.generated_scores (
  id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  analysis_id uuid NOT NULL REFERENCES public.analyses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  target_key text,
  format text CHECK (format IN ('musicxml', 'pdf', 'lilypond')),
  storage_path text,
  created_at timestamp with time zone DEFAULT now()
);

-- ============================================================
-- 3. SEED INITIAL DATA (PLANS & INSTRUMENTS)
-- ============================================================

-- Seed Pricing Plans
INSERT INTO public.plans (id, name, max_file_size_mb, can_upload_video, can_upload_pdf, max_uploads_per_month, price) VALUES
  ('448e89ad-3db2-4e9f-864a-38d5db912ea3', 'Gratuit', 10, false, false, 10, 0.00),
  ('127a5d11-5cb2-482a-adff-8ef64c58be2c', 'Premium', 25, true, true, 50, 9.99),
  ('a8d29b01-fb25-4cde-84d5-89f50cbcd194', 'Pro', 100, true, true, 200, 19.99)
ON CONFLICT (name) DO UPDATE SET
  max_file_size_mb = EXCLUDED.max_file_size_mb,
  can_upload_video = EXCLUDED.can_upload_video,
  can_upload_pdf = EXCLUDED.can_upload_pdf,
  max_uploads_per_month = EXCLUDED.max_uploads_per_month,
  price = EXCLUDED.price;

-- Seed Instruments (exactly matching Flutter catalog)
INSERT INTO public.instruments (id, name, emoji, family, difficulty, soundfont_id) VALUES
  ('guitar_acoustic', 'Guitare acoustique', '🎸', 'cordes', 2, 'acoustic_guitar_nylon'),
  ('guitar_electric', 'Guitare électrique', '🎸', 'cordes', 3, 'electric_guitar_clean'),
  ('piano', 'Piano', '🎹', 'touches', 3, 'acoustic_grand_piano'),
  ('violin', 'Violon', '🎻', 'cordes', 4, 'violin'),
  ('flute', 'Flûte traversière', '🪈', 'vents', 3, 'flute'),
  ('saxophone', 'Saxophone', '🎷', 'vents', 3, 'tenor_sax'),
  ('trumpet', 'Trompette', '🎺', 'vents', 4, 'trumpet'),
  ('bass', 'Guitare basse', '🎸', 'cordes', 2, 'electric_bass_finger'),
  ('drums', 'Batterie', '🥁', 'percussions', 3, 'standard_drum_kit'),
  ('cello', 'Violoncelle', '🎻', 'cordes', 5, 'cello'),
  ('ukulele', 'Ukulélé', '🪗', 'cordes', 1, 'acoustic_guitar_nylon'),
  ('harmonica', 'Harmonica', '🪗', 'vents', 2, 'harmonica')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  emoji = EXCLUDED.emoji,
  family = EXCLUDED.family,
  difficulty = EXCLUDED.difficulty,
  soundfont_id = EXCLUDED.soundfont_id;

-- ============================================================
-- 4. STORAGE BUCKETS PROVISIONING
-- ============================================================

-- Provision standard storage buckets via Supabase public schema storage tables
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('audio', 'audio', true),
  ('videos', 'videos', true),
  ('partitions', 'partitions', true),
  ('music-files', 'music-files', false),
  ('midi-outputs', 'midi-outputs', true),
  ('generated-audio', 'generated-audio', true),
  ('sheet-music', 'sheet-music', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 5. RLS (ROW LEVEL SECURITY) POLICIES (MIGRATION 003)
-- ============================================================

-- Enable RLS
ALTER TABLE public.profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_instruments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analyses         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playbacks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_logs       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_results     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_scores ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to avoid errors on duplicate execution
DROP POLICY IF EXISTS "own_profile" ON public.profiles;
DROP POLICY IF EXISTS "own_sessions" ON public.sessions;
DROP POLICY IF EXISTS "own_user_instruments" ON public.user_instruments;
DROP POLICY IF EXISTS "own_files" ON public.files;
DROP POLICY IF EXISTS "own_analyses" ON public.analyses;
DROP POLICY IF EXISTS "own_subscriptions" ON public.subscriptions;
DROP POLICY IF EXISTS "own_playbacks" ON public.playbacks;
DROP POLICY IF EXISTS "own_quiz" ON public.quiz_results;
DROP POLICY IF EXISTS "own_progress" ON public.courses_progress;
DROP POLICY IF EXISTS "own_scores" ON public.generated_scores;
DROP POLICY IF EXISTS "read_instruments" ON public.instruments;
DROP POLICY IF EXISTS "read_plans" ON public.plans;

-- Create policies : Users access only their own rows
CREATE POLICY "own_profile" ON public.profiles
  FOR ALL USING (id = auth.uid());

CREATE POLICY "own_sessions" ON public.sessions
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_user_instruments" ON public.user_instruments
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_files" ON public.files
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_analyses" ON public.analyses
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_subscriptions" ON public.subscriptions
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_playbacks" ON public.playbacks
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_quiz" ON public.quiz_results
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_progress" ON public.courses_progress
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_scores" ON public.generated_scores
  FOR ALL USING (user_id = auth.uid());

-- Publicly readable tables (all authenticated/public users can read)
CREATE POLICY "read_instruments" ON public.instruments
  FOR SELECT USING (true);

CREATE POLICY "read_plans" ON public.plans
  FOR SELECT USING (true);

-- ============================================================
-- 6. AUTOMATED TRIGGER: USER PROFILE CREATION
-- ============================================================
-- When a user registers via Supabase Auth, they are automatically 
-- added to public.profiles table and subscribed to the 'Gratuit' plan.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  free_plan_id uuid;
BEGIN
  -- Get the free plan ID
  SELECT id INTO free_plan_id FROM public.plans WHERE name = 'Gratuit';
  
  -- Create profile
  INSERT INTO public.profiles (id, email, full_name, avatar_url, current_plan_id)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.raw_user_meta_data->>'avatar_url', ''),
    free_plan_id
  );
  
  -- Subscribe to Free plan
  INSERT INTO public.subscriptions (user_id, plan_id, status)
  VALUES (new.id, free_plan_id, 'active');
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 7. CONTINUOUS LEARNING SYSTEM (MIGRATION 004)
-- ============================================================
-- This system captures every meaningful user interaction and
-- aggregates it anonymously to improve recommendations for ALL
-- users, including new ones (cold-start resolution).

-- ── 7.1  learning_signals — raw micro-events ─────────────────────────────────
-- Every significant action the user takes is recorded here as an
-- immutable event. This is the raw input for all learning intelligence.
CREATE TABLE IF NOT EXISTS public.learning_signals (
  id            uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  signal_type   text NOT NULL,
  -- Signal types:
  --   'course_started'       | 'course_completed'  | 'section_completed'
  --   'quiz_passed'          | 'quiz_failed'        | 'quiz_abandoned'
  --   'analysis_done'        | 'playback_started'   | 'playback_completed'
  --   'ai_chat_message'      | 'lesson_revisited'   | 'content_skipped'
  instrument_id text REFERENCES public.instruments(id) ON DELETE SET NULL,
  topic         text,                -- e.g., 'harmonics', 'chord_progressions'
  level         text,                -- 'débutant' | 'intermédiaire' | 'avancé'
  course_id     text,                -- FK to catalog course id (text, not uuid)
  section_id    text,
  score         numeric,             -- quiz score (0-100) or null
  duration_ms   integer,             -- time spent on the content
  success       boolean,             -- did the user succeed at the task?
  metadata      jsonb,               -- any extra contextual data
  created_at    timestamp with time zone DEFAULT now()
);

-- ── 7.2  user_learning_profiles — computed per-user profile ──────────────────
-- Automatically updated by trigger after each learning_signal.
-- Provides the personalized context injected into AI prompts.
CREATE TABLE IF NOT EXISTS public.user_learning_profiles (
  user_id              uuid NOT NULL PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  primary_instrument   text REFERENCES public.instruments(id) ON DELETE SET NULL,
  current_level        text DEFAULT 'débutant',
  learning_velocity    numeric DEFAULT 1.0,   -- relative speed (1.0 = average)
  weak_topics          jsonb DEFAULT '[]',     -- topics with low scores
  strong_topics        jsonb DEFAULT '[]',     -- topics with high success
  preferred_style      text DEFAULT 'mixed',   -- 'visual' | 'audio' | 'practice' | 'mixed'
  total_practice_ms    bigint DEFAULT 0,
  streak_days          integer DEFAULT 0,
  last_activity_at     timestamp with time zone DEFAULT now(),
  completion_rate      numeric DEFAULT 0,      -- % of started courses completed
  avg_quiz_score       numeric DEFAULT 0,
  total_signals        integer DEFAULT 0,
  updated_at           timestamp with time zone DEFAULT now()
);

-- ── 7.3  global_learning_insights — anonymized aggregate stats ───────────────
-- Computed nightly from all users' signals. Used to recommend optimal
-- learning paths to NEW users with no personal history (cold-start).
CREATE TABLE IF NOT EXISTS public.global_learning_insights (
  id                    uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  instrument_id         text NOT NULL REFERENCES public.instruments(id) ON DELETE CASCADE,
  level                 text NOT NULL,
  topic                 text NOT NULL,
  avg_completion_rate   numeric DEFAULT 0,
  avg_quiz_score        numeric DEFAULT 0,
  difficulty_score      numeric DEFAULT 0,    -- 0=easy, 10=very hard (computed)
  optimal_sequence_rank integer DEFAULT 0,    -- ideal order for this topic
  total_learners        integer DEFAULT 0,
  drop_off_rate         numeric DEFAULT 0,    -- % who start but never finish
  recommended_next      jsonb DEFAULT '[]',   -- topic slugs to do next
  computed_at           timestamp with time zone DEFAULT now(),
  UNIQUE (instrument_id, level, topic)
);

-- ── 7.4  ai_conversation_memory — persistent AI chat context ─────────────────
-- Stores compressed summaries of past AI conversations per user so
-- the AI assistant remembers context across multiple app sessions.
CREATE TABLE IF NOT EXISTS public.ai_conversation_memory (
  id            uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  instrument_id text REFERENCES public.instruments(id) ON DELETE SET NULL,
  summary       text NOT NULL,          -- GPT/Claude-compressed summary of the conversation
  key_facts     jsonb DEFAULT '[]',     -- extracted facts: ["plays C minor scale well", "struggles with barre chords"]
  mood          text,                   -- 'motivated' | 'frustrated' | 'curious'
  session_count integer DEFAULT 1,     -- how many conversations contributed to this memory
  created_at    timestamp with time zone DEFAULT now(),
  updated_at    timestamp with time zone DEFAULT now()
);

-- ── 7.5  content_effectiveness_scores — content performance tracking ──────────
-- Measures how effective each course/section is at producing learning outcomes.
-- Feeds back into content ordering and AI recommendations.
CREATE TABLE IF NOT EXISTS public.content_effectiveness_scores (
  id               uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
  course_id        text NOT NULL,              -- matches catalog course id
  section_id       text,                       -- null = whole course score
  instrument_id    text REFERENCES public.instruments(id) ON DELETE SET NULL,
  level            text NOT NULL,
  completion_rate  numeric DEFAULT 0,          -- % of users who finish
  avg_time_ms      bigint DEFAULT 0,           -- avg time to complete
  avg_post_score   numeric DEFAULT 0,          -- avg quiz score AFTER this content
  revisit_rate     numeric DEFAULT 0,          -- how often users come back
  effectiveness_score numeric DEFAULT 0,       -- composite score 0-100
  sample_size      integer DEFAULT 0,
  computed_at      timestamp with time zone DEFAULT now()
);
-- Partial unique indexes replace the COALESCE-based UNIQUE constraint
-- (PostgreSQL does not allow function calls inside UNIQUE constraints).
CREATE UNIQUE INDEX IF NOT EXISTS uidx_ces_no_section
  ON public.content_effectiveness_scores (course_id, instrument_id, level)
  WHERE section_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_ces_with_section
  ON public.content_effectiveness_scores (course_id, section_id, instrument_id, level)
  WHERE section_id IS NOT NULL;

-- ============================================================
-- 8. LEARNING SYSTEM — SQL FUNCTIONS
-- ============================================================

-- ── 8.1  fn_update_user_learning_profile() — triggered after each signal ─────
CREATE OR REPLACE FUNCTION public.fn_update_user_learning_profile()
RETURNS trigger AS $$
DECLARE
  v_avg_score     numeric;
  v_completion    numeric;
  v_total         integer;
  v_weak_topics   jsonb;
  v_strong_topics jsonb;
BEGIN
  -- Aggregate quiz scores for this user
  SELECT
    COALESCE(AVG(score), 0),
    COUNT(*)
  INTO v_avg_score, v_total
  FROM public.learning_signals
  WHERE user_id = NEW.user_id
    AND signal_type IN ('quiz_passed', 'quiz_failed')
    AND score IS NOT NULL;

  -- Compute course completion rate
  SELECT
    COALESCE(
      COUNT(*) FILTER (WHERE signal_type = 'course_completed')::numeric
      / NULLIF(COUNT(*) FILTER (WHERE signal_type = 'course_started'), 0),
      0
    ) * 100
  INTO v_completion
  FROM public.learning_signals
  WHERE user_id = NEW.user_id;

  -- Compute weak topics (avg score < 60 from quizzes)
  SELECT COALESCE(jsonb_agg(topic), '[]'::jsonb)
  INTO v_weak_topics
  FROM (
    SELECT topic
    FROM public.learning_signals
    WHERE user_id = NEW.user_id
      AND topic IS NOT NULL
      AND score IS NOT NULL
    GROUP BY topic
    HAVING AVG(score) < 60
    LIMIT 10
  ) t;

  -- Compute strong topics (avg score >= 80)
  SELECT COALESCE(jsonb_agg(topic), '[]'::jsonb)
  INTO v_strong_topics
  FROM (
    SELECT topic
    FROM public.learning_signals
    WHERE user_id = NEW.user_id
      AND topic IS NOT NULL
      AND score IS NOT NULL
    GROUP BY topic
    HAVING AVG(score) >= 80
    LIMIT 10
  ) t;

  -- Upsert the profile
  INSERT INTO public.user_learning_profiles (
    user_id,
    primary_instrument,
    current_level,
    avg_quiz_score,
    completion_rate,
    total_signals,
    weak_topics,
    strong_topics,
    last_activity_at,
    updated_at
  )
  VALUES (
    NEW.user_id,
    NEW.instrument_id,
    COALESCE(NEW.level, 'débutant'),
    v_avg_score,
    v_completion,
    v_total,
    COALESCE(v_weak_topics, '[]'),
    COALESCE(v_strong_topics, '[]'),
    now(),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    primary_instrument = COALESCE(EXCLUDED.primary_instrument, user_learning_profiles.primary_instrument),
    current_level      = COALESCE(EXCLUDED.current_level, user_learning_profiles.current_level),
    avg_quiz_score     = EXCLUDED.avg_quiz_score,
    completion_rate    = EXCLUDED.completion_rate,
    total_signals      = EXCLUDED.total_signals,
    weak_topics        = EXCLUDED.weak_topics,
    strong_topics      = EXCLUDED.strong_topics,
    last_activity_at   = EXCLUDED.last_activity_at,
    updated_at         = EXCLUDED.updated_at;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_learning_signal_inserted ON public.learning_signals;
CREATE TRIGGER on_learning_signal_inserted
  AFTER INSERT ON public.learning_signals
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_user_learning_profile();

-- ── 8.2  fn_refresh_global_insights() — nightly aggregate ───────────────────
-- Call this daily via pg_cron or a Supabase Edge Function cron job.
CREATE OR REPLACE FUNCTION public.fn_refresh_global_insights()
RETURNS void AS $$
BEGIN
  -- Refresh completion rates and quiz scores grouped by instrument/level/topic
  INSERT INTO public.global_learning_insights (
    instrument_id, level, topic,
    avg_completion_rate, avg_quiz_score, difficulty_score,
    total_learners, drop_off_rate, computed_at
  )
  SELECT
    ls.instrument_id,
    ls.level,
    ls.topic,
    COALESCE(
      COUNT(*) FILTER (WHERE ls.signal_type = 'course_completed')::numeric
      / NULLIF(COUNT(DISTINCT ls.user_id), 0), 0
    ) * 100  AS avg_completion_rate,
    COALESCE(AVG(ls.score) FILTER (WHERE ls.score IS NOT NULL), 0) AS avg_quiz_score,
    -- difficulty: inverse of avg_quiz_score, capped to 10
    LEAST(10, GREATEST(0, 10 - (COALESCE(AVG(ls.score) FILTER (WHERE ls.score IS NOT NULL), 50) / 10))) AS difficulty_score,
    COUNT(DISTINCT ls.user_id) AS total_learners,
    COALESCE(
      COUNT(*) FILTER (WHERE ls.signal_type = 'course_started')::numeric
      - COUNT(*) FILTER (WHERE ls.signal_type = 'course_completed')::numeric,
      0
    ) / NULLIF(COUNT(*) FILTER (WHERE ls.signal_type = 'course_started'), 0)::numeric AS drop_off_rate,
    now()
  FROM public.learning_signals ls
  WHERE ls.instrument_id IS NOT NULL
    AND ls.level IS NOT NULL
    AND ls.topic IS NOT NULL
  GROUP BY ls.instrument_id, ls.level, ls.topic
  ON CONFLICT (instrument_id, level, topic) DO UPDATE SET
    avg_completion_rate = EXCLUDED.avg_completion_rate,
    avg_quiz_score      = EXCLUDED.avg_quiz_score,
    difficulty_score    = EXCLUDED.difficulty_score,
    total_learners      = EXCLUDED.total_learners,
    drop_off_rate       = EXCLUDED.drop_off_rate,
    computed_at         = EXCLUDED.computed_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 8.3  fn_get_recommended_courses(user_id, instrument_id, level) ────────────
-- RPC called from Flutter to get personalized course recommendations.
-- Falls back to global insights for new users (cold-start).
CREATE OR REPLACE FUNCTION public.fn_get_recommended_courses(
  p_user_id      uuid,
  p_instrument   text,
  p_level        text
)
RETURNS TABLE (
  topic              text,
  difficulty_score   numeric,
  avg_quiz_score     numeric,
  is_weak_topic      boolean,
  total_learners     integer,
  recommended_next   jsonb,
  priority_rank      integer
) AS $$
DECLARE
  v_weak_topics jsonb := '[]';
BEGIN
  -- Fetch user's known weak topics (empty for new users → no penalty)
  SELECT COALESCE(ulp.weak_topics, '[]'::jsonb)
  INTO v_weak_topics
  FROM public.user_learning_profiles ulp
  WHERE ulp.user_id = p_user_id;

  RETURN QUERY
  SELECT
    g.topic,
    g.difficulty_score,
    g.avg_quiz_score,
    -- Mark as weak if this topic appears in the user's weak_topics list
    (v_weak_topics @> to_jsonb(g.topic))                AS is_weak_topic,
    g.total_learners,
    g.recommended_next,
    -- Priority rank: weak topics first, then by difficulty ascending (easiest first)
    ROW_NUMBER() OVER (
      ORDER BY
        (v_weak_topics @> to_jsonb(g.topic)) DESC,  -- weak topics up
        g.difficulty_score ASC,                       -- easiest non-weak first
        g.total_learners DESC                         -- popular topics preferred
    )::integer                                        AS priority_rank
  FROM public.global_learning_insights g
  WHERE g.instrument_id = p_instrument
    AND g.level = p_level
  ORDER BY priority_rank;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 8.4  fn_get_user_ai_context(user_id) — builds IA prompt context ──────────
-- Called by the backend before each AI chat request to inject rich
-- personalized context into the Claude/Gemini system prompt.
CREATE OR REPLACE FUNCTION public.fn_get_user_ai_context(p_user_id uuid)
RETURNS jsonb AS $$
DECLARE
  v_profile  public.user_learning_profiles%ROWTYPE;
  v_memory   public.ai_conversation_memory%ROWTYPE;
  v_result   jsonb := '{}'::jsonb;
BEGIN
  -- Load user learning profile
  SELECT * INTO v_profile
  FROM public.user_learning_profiles
  WHERE user_id = p_user_id;

  -- Load latest conversation memory for primary instrument
  SELECT * INTO v_memory
  FROM public.ai_conversation_memory
  WHERE user_id = p_user_id
  ORDER BY updated_at DESC
  LIMIT 1;

  v_result := jsonb_build_object(
    'has_profile',       v_profile.user_id IS NOT NULL,
    'primary_instrument', COALESCE(v_profile.primary_instrument, 'unknown'),
    'current_level',     COALESCE(v_profile.current_level, 'débutant'),
    'avg_quiz_score',    COALESCE(v_profile.avg_quiz_score, 0),
    'completion_rate',   COALESCE(v_profile.completion_rate, 0),
    'weak_topics',       COALESCE(v_profile.weak_topics, '[]'),
    'strong_topics',     COALESCE(v_profile.strong_topics, '[]'),
    'streak_days',       COALESCE(v_profile.streak_days, 0),
    'total_practice_ms', COALESCE(v_profile.total_practice_ms, 0),
    'memory_summary',    COALESCE(v_memory.summary, ''),
    'memory_key_facts',  COALESCE(v_memory.key_facts, '[]'),
    'memory_mood',       COALESCE(v_memory.mood, 'neutral')
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 8.5  fn_ensure_user_profile() — guarantee profile exists ─────────────────
-- Creates an empty profile if not yet computed (e.g., brand new user).
CREATE OR REPLACE FUNCTION public.fn_ensure_user_profile(p_user_id uuid)
RETURNS void AS $$
BEGIN
  INSERT INTO public.user_learning_profiles (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 8.6  fn_update_streak() — daily streak tracker ───────────────────────────
CREATE OR REPLACE FUNCTION public.fn_update_streak()
RETURNS trigger AS $$
DECLARE
  v_last_date date;
  v_today     date := CURRENT_DATE;
BEGIN
  SELECT last_activity_at::date
  INTO v_last_date
  FROM public.user_learning_profiles
  WHERE user_id = NEW.user_id;

  IF v_last_date IS NULL THEN
    -- First ever signal — streak stays at 1 (set by main trigger)
    NULL;
  ELSIF v_last_date = v_today - INTERVAL '1 day' THEN
    -- Consecutive day → increment streak
    UPDATE public.user_learning_profiles
    SET streak_days = streak_days + 1
    WHERE user_id = NEW.user_id;
  ELSIF v_last_date < v_today - INTERVAL '1 day' THEN
    -- Gap in days → reset streak
    UPDATE public.user_learning_profiles
    SET streak_days = 1
    WHERE user_id = NEW.user_id;
  END IF;
  -- Same day → no change to streak

  -- Update total practice time
  IF NEW.duration_ms IS NOT NULL THEN
    UPDATE public.user_learning_profiles
    SET total_practice_ms = total_practice_ms + NEW.duration_ms
    WHERE user_id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_learning_signal_streak ON public.learning_signals;
CREATE TRIGGER on_learning_signal_streak
  AFTER INSERT ON public.learning_signals
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_streak();

-- ── 8.7  Ensure profile exists on new user creation ─────────────────────────
-- Extend the existing handle_new_user trigger to also init the learning profile.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  free_plan_id uuid;
BEGIN
  SELECT id INTO free_plan_id FROM public.plans WHERE name = 'Gratuit';

  INSERT INTO public.profiles (id, email, full_name, avatar_url, current_plan_id)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.raw_user_meta_data->>'avatar_url', ''),
    free_plan_id
  );

  INSERT INTO public.subscriptions (user_id, plan_id, status)
  VALUES (new.id, free_plan_id, 'active');

  -- ✨ NEW: Initialize an empty learning profile immediately on signup
  INSERT INTO public.user_learning_profiles (user_id)
  VALUES (new.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 9. RLS POLICIES — Learning System Tables
-- ============================================================

ALTER TABLE public.learning_signals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_learning_profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.global_learning_insights      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversation_memory        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_effectiveness_scores  ENABLE ROW LEVEL SECURITY;

-- Drop existing to allow idempotent re-runs
DROP POLICY IF EXISTS "own_learning_signals"         ON public.learning_signals;
DROP POLICY IF EXISTS "own_learning_profile"         ON public.user_learning_profiles;
DROP POLICY IF EXISTS "read_global_insights"         ON public.global_learning_insights;
DROP POLICY IF EXISTS "own_ai_memory"                ON public.ai_conversation_memory;
DROP POLICY IF EXISTS "read_content_effectiveness"   ON public.content_effectiveness_scores;
DROP POLICY IF EXISTS "own_usage_logs"               ON public.usage_logs;

-- Users can only read/write their own signals
CREATE POLICY "own_learning_signals" ON public.learning_signals
  FOR ALL USING (user_id = auth.uid());

-- Users can only read/write their own learning profile
CREATE POLICY "own_learning_profile" ON public.user_learning_profiles
  FOR ALL USING (user_id = auth.uid());

-- Global insights are read-only for all authenticated users
-- (no individual data exposed — purely aggregated/anonymous)
CREATE POLICY "read_global_insights" ON public.global_learning_insights
  FOR SELECT USING (auth.role() = 'authenticated');

-- Users own their AI conversation memories
CREATE POLICY "own_ai_memory" ON public.ai_conversation_memory
  FOR ALL USING (user_id = auth.uid());

-- Content effectiveness is read-only for all authenticated users
CREATE POLICY "read_content_effectiveness" ON public.content_effectiveness_scores
  FOR SELECT USING (auth.role() = 'authenticated');

-- Usage logs: own rows
CREATE POLICY "own_usage_logs" ON public.usage_logs
  FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- 10. INDEXES — Performance optimization
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_learning_signals_user_type
  ON public.learning_signals (user_id, signal_type);

CREATE INDEX IF NOT EXISTS idx_learning_signals_instrument_topic
  ON public.learning_signals (instrument_id, topic, level);

CREATE INDEX IF NOT EXISTS idx_global_insights_instrument_level
  ON public.global_learning_insights (instrument_id, level);

CREATE INDEX IF NOT EXISTS idx_ai_memory_user_updated
  ON public.ai_conversation_memory (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_content_effectiveness_course
  ON public.content_effectiveness_scores (course_id, instrument_id, level);

-- ============================================================
-- 🎉 SUCCESS: Script fully compiled!
-- Continuous Learning System (Migration 004) added.
-- ============================================================
