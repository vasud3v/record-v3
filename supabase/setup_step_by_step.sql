-- ============================================
-- STEP 1: Create the recordings table
-- ============================================
-- Run this first
CREATE TABLE IF NOT EXISTS recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT NOT NULL,
    site TEXT NOT NULL CHECK (site IN ('chaturbate', 'stripchat')),
    gofile_url TEXT NOT NULL,
    gofile_code TEXT NOT NULL,
    gofile_file_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    duration NUMERIC(10, 2),
    resolution INTEGER,
    framerate INTEGER,
    recorded_at TIMESTAMPTZ NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    md5 TEXT,
    room_title TEXT,
    gender TEXT,
    num_viewers INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- STEP 2: Create indexes
-- ============================================
-- Run this after table is created
CREATE INDEX IF NOT EXISTS idx_recordings_username ON recordings(username);
CREATE INDEX IF NOT EXISTS idx_recordings_site ON recordings(site);
CREATE INDEX IF NOT EXISTS idx_recordings_recorded_at ON recordings(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_recordings_uploaded_at ON recordings(uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_recordings_username_site ON recordings(username, site);

-- ============================================
-- STEP 3: Create trigger function
-- ============================================
-- Run this after indexes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 4: Create trigger
-- ============================================
-- Run this after function
DROP TRIGGER IF EXISTS update_recordings_updated_at ON recordings;
CREATE TRIGGER update_recordings_updated_at
    BEFORE UPDATE ON recordings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 5: Enable RLS and create policies
-- ============================================
-- Run this after trigger
ALTER TABLE recordings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON recordings;
CREATE POLICY "Allow all operations for authenticated users"
    ON recordings
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Optional: Uncomment to allow anonymous read access
-- DROP POLICY IF EXISTS "Allow read access for anonymous users" ON recordings;
-- CREATE POLICY "Allow read access for anonymous users"
--     ON recordings
--     FOR SELECT
--     TO anon
--     USING (true);

-- ============================================
-- STEP 6: Create summary view
-- ============================================
-- Run this last
CREATE OR REPLACE VIEW recordings_summary AS
SELECT 
    username,
    site,
    COUNT(*) as total_recordings,
    SUM(file_size) as total_size_bytes,
    SUM(duration) as total_duration_seconds,
    MIN(recorded_at) as first_recording,
    MAX(recorded_at) as latest_recording,
    AVG(num_viewers) as avg_viewers
FROM recordings
GROUP BY username, site
ORDER BY latest_recording DESC;

-- Grant access to the view
GRANT SELECT ON recordings_summary TO authenticated;
GRANT SELECT ON recordings_summary TO anon;

-- ============================================
-- STEP 7: Test the setup
-- ============================================
-- Run this to verify everything works
-- This should return 0 rows but no errors
SELECT * FROM recordings LIMIT 1;
SELECT * FROM recordings_summary LIMIT 1;

-- ============================================
-- DONE! Your database is ready.
-- ============================================
