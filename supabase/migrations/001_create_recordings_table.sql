-- Create recordings table to store GoFile links and metadata
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

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_recordings_username ON recordings(username);
CREATE INDEX IF NOT EXISTS idx_recordings_site ON recordings(site);
CREATE INDEX IF NOT EXISTS idx_recordings_recorded_at ON recordings(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_recordings_uploaded_at ON recordings(uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_recordings_username_site ON recordings(username, site);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS update_recordings_updated_at ON recordings;
CREATE TRIGGER update_recordings_updated_at
    BEFORE UPDATE ON recordings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE recordings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON recordings;
DROP POLICY IF EXISTS "Allow read access for anonymous users" ON recordings;

-- Create policy to allow all operations for authenticated users
CREATE POLICY "Allow all operations for authenticated users"
    ON recordings
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Create policy to allow read access for anonymous users (optional)
-- Uncomment if you want public read access
-- CREATE POLICY "Allow read access for anonymous users"
--     ON recordings
--     FOR SELECT
--     TO anon
--     USING (true);

-- Create a view for easy querying
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

-- Add comments for documentation
COMMENT ON TABLE recordings IS 'Stores metadata and GoFile links for recorded streams';
COMMENT ON COLUMN recordings.username IS 'Channel username';
COMMENT ON COLUMN recordings.site IS 'Platform: chaturbate or stripchat';
COMMENT ON COLUMN recordings.gofile_url IS 'GoFile download page URL';
COMMENT ON COLUMN recordings.gofile_code IS 'GoFile content code';
COMMENT ON COLUMN recordings.gofile_file_id IS 'GoFile file ID';
COMMENT ON COLUMN recordings.file_name IS 'Original filename';
COMMENT ON COLUMN recordings.file_size IS 'File size in bytes';
COMMENT ON COLUMN recordings.duration IS 'Recording duration in seconds';
COMMENT ON COLUMN recordings.resolution IS 'Video resolution (e.g., 1080 for 1080p)';
COMMENT ON COLUMN recordings.framerate IS 'Video framerate (FPS)';
COMMENT ON COLUMN recordings.recorded_at IS 'When the stream was recorded';
COMMENT ON COLUMN recordings.uploaded_at IS 'When the file was uploaded to GoFile';
