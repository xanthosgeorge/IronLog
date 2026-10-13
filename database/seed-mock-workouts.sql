-- Supply an existing registered user's email with psql -v user_email=...
\set ON_ERROR_STOP on
BEGIN;
SELECT set_config('ironlog.seed_email', lower(:'user_email'), true);
DO $$
DECLARE
  athlete uuid;
  session_id uuid;
  group_id uuid;
  exercise_id uuid;
  workout_exercise_id uuid;
  workout record;
  prescription record;
BEGIN
  SELECT "Id" INTO STRICT athlete FROM users WHERE lower("Email") = current_setting('ironlog.seed_email');
  PERFORM pg_advisory_xact_lock(hashtextextended(athlete::text, 0));
  FOR workout IN SELECT * FROM (VALUES
    ('Upper A', '2026-10-05 17:00:00+03'::timestamptz, 60),
    ('Lower A', '2026-10-06 17:00:00+03'::timestamptz, 65),
    ('Upper B', '2026-10-09 17:00:00+03'::timestamptz, 55),
    ('Lower B', '2026-10-10 17:00:00+03'::timestamptz, 65)
  ) AS w(title, session_date, duration) LOOP
    IF EXISTS (SELECT 1 FROM workout_sessions WHERE "UserId" = athlete
      AND "Title" = workout.title AND "SessionDate" = workout.session_date
      AND "Notes" = 'Mock workout for testing the application.') THEN
      CONTINUE;
    END IF;
    session_id := gen_random_uuid();
    INSERT INTO workout_sessions ("Id", "UserId", "Title", "SessionDate", "DurationMinutes", "Notes", "CreatedAt", "TotalLoad")
    VALUES (session_id, athlete, workout.title, workout.session_date, workout.duration, 'Mock workout for testing the application.', now(), 0);
    FOR prescription IN SELECT * FROM (VALUES
      ('Upper A', 1, 'Bench Press', 'Chest', 'Barbell', 60, 8),
      ('Upper A', 2, 'Barbell Row', 'Back', 'Barbell', 50, 10),
      ('Upper A', 3, 'Shoulder Press', 'Shoulders', 'Dumbbell', 16, 10),
      ('Upper A', 4, 'Lat Pulldown', 'Back', 'Cable', 45, 12),
      ('Upper A', 5, 'Biceps Curl', 'Biceps', 'Dumbbell', 12, 12),
      ('Upper B', 1, 'Incline Dumbbell Press', 'Chest', 'Dumbbell', 22, 10),
      ('Upper B', 2, 'Lat Pulldown', 'Back', 'Cable', 50, 10),
      ('Upper B', 3, 'Seated Cable Row', 'Back', 'Cable', 45, 12),
      ('Upper B', 4, 'Lateral Raise', 'Shoulders', 'Dumbbell', 8, 15),
      ('Upper B', 5, 'Triceps Pushdown', 'Triceps', 'Cable', 25, 12),
      ('Lower A', 1, 'Back Squat', 'Quadriceps', 'Barbell', 80, 8),
      ('Lower A', 2, 'Romanian Deadlift', 'Hamstrings', 'Barbell', 70, 10),
      ('Lower A', 3, 'Leg Press', 'Quadriceps', 'Machine', 120, 12),
      ('Lower A', 4, 'Leg Curl', 'Hamstrings', 'Machine', 35, 12),
      ('Lower A', 5, 'Calf Raise', 'Calves', 'Machine', 50, 15),
      ('Lower B', 1, 'Deadlift', 'Hamstrings', 'Barbell', 100, 5),
      ('Lower B', 2, 'Front Squat', 'Quadriceps', 'Barbell', 55, 8),
      ('Lower B', 3, 'Bulgarian Split Squat', 'Glutes', 'Dumbbell', 16, 10),
      ('Lower B', 4, 'Leg Extension', 'Quadriceps', 'Machine', 40, 12),
      ('Lower B', 5, 'Calf Raise', 'Calves', 'Machine', 55, 15)
    ) AS p(title, position, exercise_name, muscle_group, equipment, weight, reps)
      WHERE p.title = workout.title ORDER BY p.position LOOP
      INSERT INTO muscle_groups ("Id", "UserId", "Name", "Description")
      VALUES (gen_random_uuid(), athlete, prescription.muscle_group, 'Mock catalog data.')
      ON CONFLICT ("UserId", "Name") DO NOTHING;
      SELECT "Id" INTO STRICT group_id FROM muscle_groups WHERE "UserId" = athlete AND "Name" = prescription.muscle_group;
      INSERT INTO exercises ("Id", "UserId", "MuscleGroupId", "Name", "EquipmentType", "IsActive")
      VALUES (gen_random_uuid(), athlete, group_id, prescription.exercise_name, prescription.equipment, true)
      ON CONFLICT ("UserId", "Name") DO NOTHING;
      SELECT "Id" INTO STRICT exercise_id FROM exercises WHERE "UserId" = athlete AND "Name" = prescription.exercise_name;
      workout_exercise_id := gen_random_uuid();
      INSERT INTO workout_exercises ("Id", "WorkoutSessionId", "ExerciseId", "OrderIndex")
      VALUES (workout_exercise_id, session_id, exercise_id, prescription.position);
      INSERT INTO workout_sets ("Id", "WorkoutExerciseId", "SetNumber", "Weight", "Reps", "Rpe", "IsWarmup")
      SELECT gen_random_uuid(), workout_exercise_id, n, prescription.weight, prescription.reps, 6 + n, false FROM generate_series(1, 3) n;
    END LOOP;
    UPDATE workout_sessions SET "TotalLoad" = (
      SELECT sum(s."Weight" * s."Reps") FROM workout_sets s
      JOIN workout_exercises e ON e."Id" = s."WorkoutExerciseId"
      WHERE e."WorkoutSessionId" = session_id
    ) WHERE "Id" = session_id;
  END LOOP;
END $$;
SELECT w."Title", w."SessionDate", w."TotalLoad", count(DISTINCT e."Id") AS exercises, count(s."Id") AS sets
FROM workout_sessions w
JOIN users u ON u."Id" = w."UserId"
JOIN workout_exercises e ON e."WorkoutSessionId" = w."Id"
JOIN workout_sets s ON s."WorkoutExerciseId" = e."Id"
WHERE lower(u."Email") = current_setting('ironlog.seed_email')
  AND w."Notes" = 'Mock workout for testing the application.'
GROUP BY w."Id" ORDER BY w."SessionDate";
COMMIT;
