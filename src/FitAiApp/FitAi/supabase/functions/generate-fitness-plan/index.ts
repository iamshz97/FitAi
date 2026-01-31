import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { user_id } = await req.json()

        // Initialize Supabase client
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // 1. Fetch user profile data
        const { data: profile, error: profileError } = await supabaseClient
            .from('user_profiles')
            .select('*')
            .eq('user_id', user_id)
            .single()

        if (profileError) throw profileError

        // 2. Build prompt for Claude
        const prompt = `You are a fitness and nutrition AI coach. Based on the following user profile, create a detailed 2-week fitness plan.

User Profile:
${JSON.stringify(profile, null, 2)}

Generate a JSON response with:
1. workout_sessions: Array of 14 workout sessions (one per day) with title, description, scheduled_for (ISO timestamp starting from 2026-02-01 07:00:00+05:30), duration_minutes, difficulty
2. exercises: Array of exercises for each workout with workout_session_index (0-13), exercise_name, sets, reps, weight_kg, rest_seconds, order_index
3. meal_plans: Array of 42 meals (3 meals per day for 14 days) with title, meal_type, description, scheduled_for (ISO timestamp), calories, protein_g, carbs_g, fat_g

Return ONLY valid JSON, no markdown.`

        // 3. Call Anthropic API
        const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: {
                'anthropic-version': '2023-06-01',
                'content-type': 'application/json',
                'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') ?? '',
            },
            body: JSON.stringify({
                model: 'claude-sonnet-4-5-20250929',
                max_tokens: 8000,
                messages: [
                    { role: 'user', content: prompt }
                ],
            }),
        })

        const anthropicData = await anthropicResponse.json()
        const aiContent = anthropicData.content[0].text

        // Parse AI response (remove markdown if present)
        let planData
        try {
            const jsonMatch = aiContent.match(/\{[\s\S]*\}/)
            planData = JSON.parse(jsonMatch ? jsonMatch[0] : aiContent)
        } catch (e) {
            planData = JSON.parse(aiContent)
        }

        // 4. Insert workout sessions
        const { data: insertedWorkouts, error: workoutError } = await supabaseClient
            .from('workout_sessions')
            .insert(
                planData.workout_sessions.map((w: any) => ({
                    user_id,
                    title: w.title,
                    description: w.description,
                    scheduled_for: w.scheduled_for,
                    duration_minutes: w.duration_minutes,
                    difficulty: w.difficulty,
                    status: 'pending'
                }))
            )
            .select()

        if (workoutError) throw workoutError

        // 5. Insert exercises for each workout
        const exercisesToInsert = planData.exercises.map((ex: any) => ({
            workout_session_id: insertedWorkouts[ex.workout_session_index].id,
            exercise_name: ex.exercise_name,
            sets: ex.sets,
            reps: ex.reps,
            weight_kg: ex.weight_kg,
            rest_seconds: ex.rest_seconds,
            order_index: ex.order_index,
            is_completed: false
        }))

        const { error: exerciseError } = await supabaseClient
            .from('workout_exercises')
            .insert(exercisesToInsert)

        if (exerciseError) throw exerciseError

        // 6. Insert meal plans
        const { error: mealError } = await supabaseClient
            .from('meal_plans')
            .insert(
                planData.meal_plans.map((m: any) => ({
                    user_id,
                    title: m.title,
                    meal_type: m.meal_type,
                    description: m.description,
                    scheduled_for: m.scheduled_for,
                    calories: m.calories,
                    protein_g: m.protein_g,
                    carbs_g: m.carbs_g,
                    fat_g: m.fat_g,
                    status: 'pending'
                }))
            )

        if (mealError) throw mealError

        return new Response(
            JSON.stringify({
                success: true,
                message: 'Fitness plan generated successfully',
                workouts_created: insertedWorkouts.length,
                meals_created: planData.meal_plans.length
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
