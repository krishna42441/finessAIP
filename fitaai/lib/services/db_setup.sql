-- Create the SQL function for MCP integration
CREATE OR REPLACE FUNCTION run_sql(query text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result json;
BEGIN
    -- Execute the query and capture the result as JSON
    EXECUTE 'WITH query_result AS (' || query || ') SELECT json_agg(query_result) FROM query_result' INTO result;
    
    -- Handle NULL result (empty result set)
    IF result IS NULL THEN
        result := '[]'::json;
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Return error information as JSON
        RETURN json_build_object(
            'error', SQLERRM,
            'detail', SQLSTATE,
            'query', query
        );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION run_sql(text) TO authenticated;

-- Row-level security policies for user data protection
-- For user_profiles table
CREATE POLICY user_profiles_select_own ON user_profiles
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY user_profiles_insert_own ON user_profiles
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_profiles_update_own ON user_profiles
    FOR UPDATE
    USING (auth.uid() = user_id);

-- For workout_plans table
CREATE POLICY workout_plans_select_own ON workout_plans
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY workout_plans_insert_own ON workout_plans
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY workout_plans_update_own ON workout_plans
    FOR UPDATE
    USING (auth.uid() = user_id);

-- For nutrition_plans table
CREATE POLICY nutrition_plans_select_own ON nutrition_plans
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY nutrition_plans_insert_own ON nutrition_plans
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY nutrition_plans_update_own ON nutrition_plans
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Create indexes to optimize queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_user_id ON workout_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plans_user_id ON nutrition_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_plan_days_plan_id ON workout_plan_days(plan_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plan_days_plan_id ON nutrition_plan_days(plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_day_id ON workout_exercises(day_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_plan_meals_day_id ON nutrition_plan_meals(day_id);

-- Create database functions for common operations
CREATE OR REPLACE FUNCTION get_user_profile(p_user_id uuid)
RETURNS SETOF user_profiles
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT * FROM user_profiles WHERE user_id = p_user_id;
$$;

CREATE OR REPLACE FUNCTION get_latest_workout_plan(p_user_id uuid)
RETURNS TABLE (
    plan_id uuid,
    plan_name text,
    plan_description text,
    plan_type text,
    plan_difficulty text,
    days_per_week int,
    created_at timestamptz,
    day_of_week int,
    workout_type text,
    exercise_name text,
    sets int,
    reps text,
    instructions text,
    rest_seconds int
)
LANGUAGE sql
SECURITY DEFINER
AS $$
    WITH latest_plan AS (
        SELECT id, plan_name, plan_description, plan_type, plan_difficulty, days_per_week, created_at
        FROM workout_plans
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT 1
    )
    SELECT 
        p.id as plan_id, 
        p.plan_name, 
        p.plan_description, 
        p.plan_type, 
        p.plan_difficulty, 
        p.days_per_week,
        p.created_at,
        d.day_of_week,
        d.workout_type,
        e.exercise_name,
        e.sets,
        e.reps,
        e.instructions,
        e.rest_seconds
    FROM latest_plan p
    JOIN workout_plan_days d ON d.plan_id = p.id
    LEFT JOIN workout_exercises e ON e.day_id = d.id
    ORDER BY d.day_of_week, e.exercise_order;
$$;

CREATE OR REPLACE FUNCTION get_latest_nutrition_plan(p_user_id uuid)
RETURNS TABLE (
    plan_id uuid,
    total_daily_calories int,
    protein_daily_grams int,
    carbs_daily_grams int,
    fat_daily_grams int,
    meals_per_day int,
    created_at timestamptz,
    day_of_week int,
    total_calories int,
    meal_name text,
    meal_time text,
    protein_grams int,
    carbs_grams int,
    fat_grams int,
    foods_json jsonb
)
LANGUAGE sql
SECURITY DEFINER
AS $$
    WITH latest_plan AS (
        SELECT id, total_daily_calories, protein_daily_grams, carbs_daily_grams, fat_daily_grams, meals_per_day, created_at
        FROM nutrition_plans
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT 1
    )
    SELECT 
        p.id as plan_id, 
        p.total_daily_calories, 
        p.protein_daily_grams, 
        p.carbs_daily_grams, 
        p.fat_daily_grams, 
        p.meals_per_day,
        p.created_at,
        d.day_of_week,
        d.total_calories,
        m.meal_name,
        m.meal_time::text,
        m.protein_grams,
        m.carbs_grams,
        m.fat_grams,
        m.foods as foods_json
    FROM latest_plan p
    JOIN nutrition_plan_days d ON d.plan_id = p.id
    LEFT JOIN nutrition_plan_meals m ON m.day_id = d.id
    ORDER BY d.day_of_week, m.meal_time;
$$; 