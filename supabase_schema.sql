-- ============================================================================
-- GymApp Supabase Schema
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard → SQL Editor
-- ============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Exercises ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 100),
  category TEXT NOT NULL,
  target_muscle TEXT NOT NULL,
  equipment TEXT NOT NULL,
  is_custom BOOLEAN NOT NULL DEFAULT false,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- ─── Routines ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS routines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 100),
  description TEXT NOT NULL DEFAULT '',
  color_hex TEXT NOT NULL DEFAULT 'FF6366F1',
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- ─── Routine Exercises ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS routine_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  routine_id UUID NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  display_order INT NOT NULL DEFAULT 0,
  target_sets INT NOT NULL DEFAULT 3,
  target_reps INT NOT NULL DEFAULT 10,
  target_weight DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- ─── Workouts ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  routine_id UUID REFERENCES routines(id) ON DELETE SET NULL,
  start_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_time TIMESTAMPTZ,
  notes TEXT NOT NULL DEFAULT '',
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- ─── Logged Sets ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS logged_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  set_number INT NOT NULL,
  weight DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  reps INT NOT NULL DEFAULT 0,
  rpe DOUBLE PRECISION,
  set_type INT NOT NULL DEFAULT 0,
  rest_seconds INT NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- ─── Row Level Security (RLS) ───────────────────────────────────────────────
-- Every user can only read/write their own data.

ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE logged_sets ENABLE ROW LEVEL SECURITY;

-- Exercises: users see global (user_id IS NULL) + their own custom ones
CREATE POLICY "Users can view global and own exercises"
  ON exercises FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);
CREATE POLICY "Users can insert own exercises"
  ON exercises FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own exercises"
  ON exercises FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own exercises"
  ON exercises FOR DELETE USING (auth.uid() = user_id);

-- Routines
CREATE POLICY "Users can view own routines"
  ON routines FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own routines"
  ON routines FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own routines"
  ON routines FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own routines"
  ON routines FOR DELETE USING (auth.uid() = user_id);

-- Routine exercises
CREATE POLICY "Users can view own routine_exercises"
  ON routine_exercises FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own routine_exercises"
  ON routine_exercises FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own routine_exercises"
  ON routine_exercises FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own routine_exercises"
  ON routine_exercises FOR DELETE USING (auth.uid() = user_id);

-- Workouts
CREATE POLICY "Users can view own workouts"
  ON workouts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own workouts"
  ON workouts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own workouts"
  ON workouts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own workouts"
  ON workouts FOR DELETE USING (auth.uid() = user_id);

-- Logged sets
CREATE POLICY "Users can view own logged_sets"
  ON logged_sets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own logged_sets"
  ON logged_sets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own logged_sets"
  ON logged_sets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own logged_sets"
  ON logged_sets FOR DELETE USING (auth.uid() = user_id);
