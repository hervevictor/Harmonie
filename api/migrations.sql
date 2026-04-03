-- ============================================================
-- MIGRATION 001 : Corrections du schéma existant
-- ============================================================

-- Fix 1 : instrument_id dans sessions doit être uuid, pas text
ALTER TABLE public.sessions
  ALTER COLUMN instrument_id TYPE uuid USING instrument_id::uuid;

ALTER TABLE public.sessions
  ADD CONSTRAINT sessions_instrument_id_fkey
  FOREIGN KEY (instrument_id) REFERENCES public.instruments(id);

-- Fix 2 : user_instruments.instrument_id doit être uuid
ALTER TABLE public.user_instruments
  ALTER COLUMN instrument_id TYPE uuid USING instrument_id::uuid;

ALTER TABLE public.user_instruments
  ADD CONSTRAINT user_instruments_instrument_id_fkey
  FOREIGN KEY (instrument_id) REFERENCES public.instruments(id);

-- Fix 3 : Ajouter current_plan_id sur profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS current_plan_id uuid REFERENCES public.plans(id);

-- ============================================================
-- MIGRATION 002 : Nouvelles tables pédagogiques
-- ============================================================

-- Table quiz_results : résultats des quiz par utilisateur
CREATE TABLE IF NOT EXISTS public.quiz_results (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  analysis_id uuid REFERENCES public.analyses(id),
  instrument_id uuid REFERENCES public.instruments(id),
  topic text NOT NULL,
  level text NOT NULL CHECK (level IN ('débutant', 'intermédiaire', 'avancé')),
  score integer NOT NULL CHECK (score >= 0),
  total_questions integer NOT NULL CHECK (total_questions > 0),
  answers jsonb,                   -- détail de chaque réponse
  duration_seconds integer,        -- temps pour compléter le quiz
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quiz_results_pkey PRIMARY KEY (id)
);

-- Table courses_progress : suivi pédagogique
CREATE TABLE IF NOT EXISTS public.courses_progress (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  instrument_id uuid REFERENCES public.instruments(id),
  topic text NOT NULL,
  level text NOT NULL,
  course_data jsonb,               -- contenu complet du cours généré
  completed boolean DEFAULT false,
  completion_percentage integer DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),
  last_accessed_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT courses_progress_pkey PRIMARY KEY (id),
  CONSTRAINT courses_progress_unique UNIQUE (user_id, instrument_id, topic, level)
);

-- Table generated_scores : partitions générées
CREATE TABLE IF NOT EXISTS public.generated_scores (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  analysis_id uuid NOT NULL REFERENCES public.analyses(id),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  target_key text,
  format text CHECK (format IN ('musicxml', 'pdf', 'lilypond')),
  storage_path text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT generated_scores_pkey PRIMARY KEY (id)
);

-- ============================================================
-- MIGRATION 003 : RLS (Row Level Security) policies
-- ============================================================

ALTER TABLE public.analyses         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_results     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playbacks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_logs       ENABLE ROW LEVEL SECURITY;

-- Policies : chaque utilisateur accède uniquement à ses données
CREATE POLICY "own_analyses"   ON public.analyses
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_files"      ON public.files
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_quiz"       ON public.quiz_results
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_progress"   ON public.courses_progress
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_scores"     ON public.generated_scores
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_playbacks"  ON public.playbacks
  FOR ALL USING (user_id = auth.uid());

-- instruments : lecture publique
CREATE POLICY "read_instruments" ON public.instruments
  FOR SELECT USING (true);

-- plans : lecture publique
CREATE POLICY "read_plans" ON public.plans
  FOR SELECT USING (true);
