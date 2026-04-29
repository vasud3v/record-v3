# Supabase Setup Troubleshooting

## Error: "column 'username' does not exist"

This error typically occurs when:
1. The table hasn't been created yet
2. You're running queries in the wrong order
3. There's a typo in the table name

### Solution: Step-by-Step Setup

#### Method 1: Run Complete Migration (Recommended)

1. Go to your Supabase project dashboard
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the **entire contents** of `supabase/migrations/001_create_recordings_table.sql`
5. Paste into the SQL editor
6. Click **Run** (or press Ctrl+Enter)
7. Wait for "Success. No rows returned"

#### Method 2: Run Step-by-Step

If the complete migration fails, use `supabase/setup_step_by_step.sql`:

1. Open `supabase/setup_step_by_step.sql`
2. In Supabase SQL Editor, run each step separately:

**Step 1: Create Table**
```sql
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
```

**Step 2: Create Indexes**
```sql
CREATE INDEX IF NOT EXISTS idx_recordings_username ON recordings(username);
CREATE INDEX IF NOT EXISTS idx_recordings_site ON recordings(site);
CREATE INDEX IF NOT EXISTS idx_recordings_recorded_at ON recordings(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_recordings_uploaded_at ON recordings(uploaded_at DESC);
CREATE INDEX IF NOT EXISTS idx_recordings_username_site ON recordings(username, site);
```

**Step 3: Create Function**
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Step 4: Create Trigger**
```sql
DROP TRIGGER IF EXISTS update_recordings_updated_at ON recordings;
CREATE TRIGGER update_recordings_updated_at
    BEFORE UPDATE ON recordings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**Step 5: Enable RLS**
```sql
ALTER TABLE recordings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON recordings;
CREATE POLICY "Allow all operations for authenticated users"
    ON recordings
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);
```

**Step 6: Create View**
```sql
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

GRANT SELECT ON recordings_summary TO authenticated;
GRANT SELECT ON recordings_summary TO anon;
```

**Step 7: Verify**
```sql
-- Should return 0 rows but no errors
SELECT * FROM recordings LIMIT 1;
SELECT * FROM recordings_summary LIMIT 1;
```

### Verify Table Exists

Run this query to check if the table was created:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'recordings';
```

Should return:
```
table_name
----------
recordings
```

### Verify Columns

Run this to see all columns:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'recordings'
ORDER BY ordinal_position;
```

Should show all 18 columns including `username`.

## Other Common Errors

### Error: "permission denied for table recordings"

**Cause**: RLS is enabled but no policies allow access.

**Solution**: Run the RLS policy creation (Step 5 above).

### Error: "relation 'recordings' does not exist"

**Cause**: Table wasn't created.

**Solution**: Run Step 1 to create the table.

### Error: "function update_updated_at_column() does not exist"

**Cause**: Function wasn't created before trigger.

**Solution**: Run Step 3 before Step 4.

### Error: "new row violates row-level security policy"

**Cause**: Using anon key but policy only allows authenticated users.

**Solution**: Either:
1. Use service_role key in GoondVR config
2. Or add anon policy:
```sql
CREATE POLICY "Allow insert for anon"
    ON recordings
    FOR INSERT
    TO anon
    WITH CHECK (true);
```

## Testing the Setup

### Test 1: Insert Sample Data

```sql
INSERT INTO recordings (
    username,
    site,
    gofile_url,
    gofile_code,
    gofile_file_id,
    file_name,
    file_size,
    duration,
    resolution,
    framerate,
    recorded_at
) VALUES (
    'test_channel',
    'chaturbate',
    'https://gofile.io/d/ABC123',
    'ABC123',
    'file123',
    'test_channel_2024-01-01.mp4',
    1073741824,
    3600.00,
    1080,
    60,
    NOW()
);
```

### Test 2: Query Data

```sql
SELECT * FROM recordings;
```

### Test 3: Check Summary

```sql
SELECT * FROM recordings_summary;
```

### Test 4: Delete Test Data

```sql
DELETE FROM recordings WHERE username = 'test_channel';
```

## Using Supabase CLI

If you prefer command line:

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Run migration
supabase db push

# Or run SQL file directly
supabase db execute -f supabase/migrations/001_create_recordings_table.sql
```

## Getting Help

If you're still having issues:

1. **Check Supabase Logs**
   - Dashboard → Logs → Postgres Logs

2. **Verify Project Status**
   - Dashboard → Settings → General
   - Ensure project is "Active"

3. **Check API Keys**
   - Dashboard → Settings → API
   - Verify keys are correct

4. **Test Connection**
   ```bash
   curl https://your-project.supabase.co/rest/v1/ \
     -H "apikey: your-anon-key"
   ```

5. **Contact Support**
   - Supabase Discord: https://discord.supabase.com
   - GitHub Issues: Include error message and steps

## Quick Reset

If you want to start fresh:

```sql
-- WARNING: This deletes all data!
DROP TABLE IF EXISTS recordings CASCADE;
DROP VIEW IF EXISTS recordings_summary CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Then run the migration again
```

## Success Checklist

- [ ] Table `recordings` exists
- [ ] All 18 columns present
- [ ] Indexes created
- [ ] Trigger function created
- [ ] Trigger attached
- [ ] RLS enabled
- [ ] Policies created
- [ ] View created
- [ ] Test insert works
- [ ] Test query works
- [ ] Ready to use!
