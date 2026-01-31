-- ================================================
-- 1. USER PROFILES TABLE
-- ================================================
CREATE TABLE user_profiles_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  fitness_goal TEXT, -- 'weight_loss', 'muscle_gain', 'endurance', etc.
  experience_level TEXT, -- 'beginner', 'intermediate', 'advanced'
  age INTEGER,
  weight_kg DECIMAL,
  height_cm DECIMAL,
  dietary_preferences TEXT, -- 'vegan', 'vegetarian', 'keto', etc.
  allergies TEXT[],
  available_equipment TEXT[],
  workout_days_per_week INTEGER,
  preferred_workout_time TEXT, -- 'morning', 'afternoon', 'evening'
  target_calories INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- 2. WORKOUT SESSIONS TABLE
-- ================================================
CREATE TABLE workout_sessions_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  scheduled_for TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER,
  difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'skipped')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- 3. WORKOUT EXERCISES TABLE
-- ================================================
CREATE TABLE workout_exercises_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_session_id UUID REFERENCES workout_sessions_v2(id) ON DELETE CASCADE NOT NULL,
  exercise_name TEXT NOT NULL,
  sets INTEGER,
  reps INTEGER,
  weight_kg DECIMAL,
  rest_seconds INTEGER,
  order_index INTEGER NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- 4. MEAL PLANS TABLE
-- ================================================
CREATE TABLE meal_plans_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  description TEXT,
  scheduled_for TIMESTAMPTZ NOT NULL,
  calories INTEGER,
  protein_g DECIMAL,
  carbs_g DECIMAL,
  fat_g DECIMAL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'skipped', 'deviated')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- 5. USER ACTIVITY LOG TABLE
-- ================================================
CREATE TABLE user_activity_log_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('workout', 'meal')),
  activity_id UUID NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('completed', 'skipped', 'commented', 'deviated')),
  comment TEXT,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================
CREATE INDEX idx_workout_sessions_v2_user_id ON workout_sessions_v2(user_id);
CREATE INDEX idx_workout_sessions_v2_scheduled ON workout_sessions_v2(scheduled_for);
CREATE INDEX idx_workout_sessions_v2_status ON workout_sessions_v2(status);

CREATE INDEX idx_workout_exercises_v2_session_id ON workout_exercises_v2(workout_session_id);
CREATE INDEX idx_workout_exercises_v2_order ON workout_exercises_v2(workout_session_id, order_index);

CREATE INDEX idx_meal_plans_v2_user_id ON meal_plans_v2(user_id);
CREATE INDEX idx_meal_plans_v2_scheduled ON meal_plans_v2(scheduled_for);
CREATE INDEX idx_meal_plans_v2_status ON meal_plans_v2(status);

CREATE INDEX idx_activity_log_v2_user_id ON user_activity_log_v2(user_id);
CREATE INDEX idx_activity_log_v2_type ON user_activity_log_v2(activity_type, activity_id);

-- ================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ================================================

-- Enable RLS on all tables
ALTER TABLE user_profiles_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_log_v2 ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
CREATE POLICY "Users can view own profile"
  ON user_profiles_v2 FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles_v2 FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles_v2 FOR UPDATE
  USING (auth.uid() = user_id);

-- Workout Sessions Policies
CREATE POLICY "Users can view own workouts"
  ON workout_sessions_v2 FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workouts"
  ON workout_sessions_v2 FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workouts"
  ON workout_sessions_v2 FOR UPDATE
  USING (auth.uid() = user_id);

-- Workout Exercises Policies
CREATE POLICY "Users can view own exercises"
  ON workout_exercises_v2 FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM workout_sessions_v2
      WHERE workout_sessions_v2.id = workout_exercises_v2.workout_session_id
      AND workout_sessions_v2.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own exercises"
  ON workout_exercises_v2 FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workout_sessions_v2
      WHERE workout_sessions_v2.id = workout_exercises_v2.workout_session_id
      AND workout_sessions_v2.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own exercises"
  ON workout_exercises_v2 FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM workout_sessions_v2
      WHERE workout_sessions_v2.id = workout_exercises_v2.workout_session_id
      AND workout_sessions_v2.user_id = auth.uid()
    )
  );

-- Meal Plans Policies
CREATE POLICY "Users can view own meals"
  ON meal_plans_v2 FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own meals"
  ON meal_plans_v2 FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own meals"
  ON meal_plans_v2 FOR UPDATE
  USING (auth.uid() = user_id);

-- Activity Log Policies
CREATE POLICY "Users can view own activity log"
  ON user_activity_log_v2 FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activity log"
  ON user_activity_log_v2 FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ================================================
-- HELPER FUNCTION FOR UPCOMING VIEW
-- ================================================
CREATE OR REPLACE FUNCTION get_upcoming_activities_v2(p_user_id UUID, p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
  type TEXT,
  id UUID,
  title TEXT,
  scheduled_for TIMESTAMPTZ,
  duration_minutes INTEGER,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    'workout'::TEXT as type,
    ws.id,
    ws.title,
    ws.scheduled_for,
    ws.duration_minutes,
    ws.status
  FROM workout_sessions_v2 ws
  WHERE ws.user_id = p_user_id 
    AND ws.status = 'pending'
    AND ws.scheduled_for >= NOW()
  
  UNION ALL
  
  SELECT 
    'meal'::TEXT as type,
    mp.id,
    mp.title,
    mp.scheduled_for,
    NULL::INTEGER as duration_minutes,
    mp.status
  FROM meal_plans_v2 mp
  WHERE mp.user_id = p_user_id
    AND mp.status = 'pending'
    AND mp.scheduled_for >= NOW()
  
  ORDER BY scheduled_for ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
