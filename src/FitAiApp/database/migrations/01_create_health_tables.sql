-- Create health_data table for raw metrics
CREATE TABLE public.health_data (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    metric_type TEXT NOT NULL,
    value NUMERIC NOT NULL,
    unit TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    source_name TEXT,
    source_bundle_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate entries for the same metric time range
    UNIQUE(user_id, metric_type, start_time, end_time)
);

-- Enable RLS for health_data
ALTER TABLE public.health_data ENABLE ROW LEVEL SECURITY;

-- Create policies for health_data
CREATE POLICY "Users can view their own health data"
    ON public.health_data
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own health data"
    ON public.health_data
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own health data"
    ON public.health_data
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Create health_data_daily table for aggregated summaries
CREATE TABLE public.health_data_daily (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    date DATE NOT NULL,
    steps_total INTEGER,
    distance_meters NUMERIC,
    active_calories_total NUMERIC,
    resting_heart_rate NUMERIC,
    avg_heart_rate NUMERIC,
    sleep_hours NUMERIC,
    workout_minutes INTEGER,
    workout_count INTEGER,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure one summary per day per user
    UNIQUE(user_id, date)
);

-- Enable RLS for health_data_daily
ALTER TABLE public.health_data_daily ENABLE ROW LEVEL SECURITY;

-- Create policies for health_data_daily
CREATE POLICY "Users can view their own daily health data"
    ON public.health_data_daily
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own daily health data"
    ON public.health_data_daily
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own daily health data"
    ON public.health_data_daily
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX idx_health_data_user_id ON public.health_data(user_id);
CREATE INDEX idx_health_data_type_time ON public.health_data(user_id, metric_type, start_time DESC);
CREATE INDEX idx_health_data_daily_user_date ON public.health_data_daily(user_id, date DESC);
