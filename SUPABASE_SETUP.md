# Supabase Integration Setup Guide

This guide explains how to set up Supabase to store GoFile links and recording metadata.

## Overview

After recordings are uploaded to GoFile, the metadata (including the GoFile download link) is automatically stored in Supabase. This provides:

- **Searchable Database**: Query recordings by username, site, date, etc.
- **Persistent Links**: Never lose GoFile links
- **Analytics**: Track total recordings, storage usage, viewer counts
- **API Access**: Build custom dashboards or integrations
- **Backup**: Metadata backup even if local files are deleted

## Architecture

```
Recording Complete
    ↓
Upload to GoFile
    ↓
Store Metadata in Supabase
    ├─ GoFile URL
    ├─ File details
    ├─ Recording metadata
    └─ Channel information
    ↓
Delete Local File
```

## Setup Steps

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Name**: goondvr-recordings (or your choice)
   - **Database Password**: Generate a strong password
   - **Region**: Choose closest to your AWS region
5. Click "Create new project"
6. Wait for project to be ready (~2 minutes)

### 2. Get API Credentials

1. In your Supabase project dashboard
2. Go to **Settings** → **API**
3. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: Long string starting with `eyJ...`

### 3. Create Database Table

#### Option A: Using SQL Editor (Recommended)

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy and paste the contents of `supabase/migrations/001_create_recordings_table.sql`
4. Click "Run" or press `Ctrl+Enter`
5. Verify table was created in **Table Editor**

#### Option B: Using Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Run migration
supabase db push
```

### 4. Configure GoondVR

#### Option A: Environment Variables (Docker/AWS)

Edit `.env`:
```bash
SUPABASE_ENABLED=true
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_API_KEY=your_anon_key_here
SUPABASE_TABLE_NAME=recordings
```

#### Option B: Configuration File

Edit `conf/settings.json`:
```json
{
  "supabase_enabled": true,
  "supabase_url": "https://your-project.supabase.co",
  "supabase_api_key": "your_anon_key_here",
  "supabase_table_name": "recordings"
}
```

#### Option C: Command Line

```bash
./goondvr \
  --supabase-enabled \
  --supabase-url "https://your-project.supabase.co" \
  --supabase-api-key "your_anon_key" \
  --supabase-table-name "recordings"
```

### 5. Test the Integration

1. Start GoondVR
2. Add a test channel
3. Wait for a recording
4. Check Supabase **Table Editor** → **recordings**
5. Verify new row with GoFile link

## Database Schema

### recordings Table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key (auto-generated) |
| username | TEXT | Channel username |
| site | TEXT | Platform (chaturbate/stripchat) |
| gofile_url | TEXT | GoFile download page URL |
| gofile_code | TEXT | GoFile content code |
| gofile_file_id | TEXT | GoFile file ID |
| file_name | TEXT | Original filename |
| file_size | BIGINT | File size in bytes |
| duration | NUMERIC | Recording duration in seconds |
| resolution | INTEGER | Video resolution (e.g., 1080) |
| framerate | INTEGER | Video framerate (FPS) |
| recorded_at | TIMESTAMPTZ | When stream was recorded |
| uploaded_at | TIMESTAMPTZ | When uploaded to GoFile |
| md5 | TEXT | File MD5 hash (from GoFile) |
| room_title | TEXT | Stream title |
| gender | TEXT | Broadcaster gender |
| num_viewers | INTEGER | Viewer count during recording |
| created_at | TIMESTAMPTZ | Row creation time |
| updated_at | TIMESTAMPTZ | Row update time |

### Indexes

- `idx_recordings_username` - Fast username lookups
- `idx_recordings_site` - Fast site filtering
- `idx_recordings_recorded_at` - Fast date sorting
- `idx_recordings_uploaded_at` - Fast upload date sorting
- `idx_recordings_username_site` - Fast combined lookups

## Querying Data

### Using Supabase Dashboard

1. Go to **Table Editor**
2. Click on **recordings** table
3. Use filters and sorting
4. Export to CSV if needed

### Using SQL Editor

```sql
-- Get all recordings for a username
SELECT * FROM recordings 
WHERE username = 'channel1' 
ORDER BY recorded_at DESC;

-- Get recordings from last 7 days
SELECT * FROM recordings 
WHERE recorded_at > NOW() - INTERVAL '7 days'
ORDER BY recorded_at DESC;

-- Get total storage per channel
SELECT 
  username,
  COUNT(*) as total_recordings,
  SUM(file_size) / 1024 / 1024 / 1024 as total_gb,
  SUM(duration) / 3600 as total_hours
FROM recordings
GROUP BY username
ORDER BY total_gb DESC;

-- Get most viewed recordings
SELECT 
  username,
  file_name,
  num_viewers,
  gofile_url,
  recorded_at
FROM recordings
WHERE num_viewers > 0
ORDER BY num_viewers DESC
LIMIT 10;
```

### Using recordings_summary View

```sql
-- Get summary statistics per channel
SELECT * FROM recordings_summary
ORDER BY latest_recording DESC;
```

### Using Supabase Client (JavaScript)

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://your-project.supabase.co',
  'your-anon-key'
)

// Get all recordings
const { data, error } = await supabase
  .from('recordings')
  .select('*')
  .order('recorded_at', { ascending: false })

// Get recordings for specific username
const { data, error } = await supabase
  .from('recordings')
  .select('*')
  .eq('username', 'channel1')
  .order('recorded_at', { ascending: false })

// Search by date range
const { data, error } = await supabase
  .from('recordings')
  .select('*')
  .gte('recorded_at', '2024-01-01')
  .lte('recorded_at', '2024-12-31')
```

## Security

### Row Level Security (RLS)

The migration enables RLS by default with these policies:

1. **Authenticated users**: Full access (read/write)
2. **Anonymous users**: No access by default

### Customizing Access

To allow public read access:

```sql
CREATE POLICY "Allow read access for anonymous users"
    ON recordings
    FOR SELECT
    TO anon
    USING (true);
```

To restrict to specific users:

```sql
-- Only allow users to see their own recordings
CREATE POLICY "Users can only see their own recordings"
    ON recordings
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);  -- Add user_id column first
```

### API Key Security

- **anon key**: Safe to use in client-side code (respects RLS)
- **service_role key**: Full access, keep secret (use for GoondVR)

For production, consider using service_role key:

```bash
SUPABASE_API_KEY=your_service_role_key_here
```

## Building a Dashboard

### Simple HTML Dashboard

```html
<!DOCTYPE html>
<html>
<head>
    <title>GoondVR Recordings</title>
    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
</head>
<body>
    <h1>My Recordings</h1>
    <div id="recordings"></div>

    <script>
        const supabase = supabase.createClient(
            'https://your-project.supabase.co',
            'your-anon-key'
        )

        async function loadRecordings() {
            const { data, error } = await supabase
                .from('recordings')
                .select('*')
                .order('recorded_at', { ascending: false })
                .limit(50)

            if (error) {
                console.error('Error:', error)
                return
            }

            const html = data.map(r => `
                <div style="border: 1px solid #ccc; padding: 10px; margin: 10px;">
                    <h3>${r.username} - ${r.site}</h3>
                    <p><strong>Recorded:</strong> ${new Date(r.recorded_at).toLocaleString()}</p>
                    <p><strong>Duration:</strong> ${(r.duration / 60).toFixed(1)} minutes</p>
                    <p><strong>Size:</strong> ${(r.file_size / 1024 / 1024).toFixed(1)} MB</p>
                    <p><strong>Viewers:</strong> ${r.num_viewers || 'N/A'}</p>
                    <a href="${r.gofile_url}" target="_blank">Download from GoFile</a>
                </div>
            `).join('')

            document.getElementById('recordings').innerHTML = html
        }

        loadRecordings()
    </script>
</body>
</html>
```

### Next.js Dashboard

See Supabase documentation for building full-featured dashboards with:
- Authentication
- Real-time updates
- Advanced filtering
- Charts and analytics

## Monitoring

### Check Integration Status

In GoondVR logs, look for:
```
[INFO] storing metadata in Supabase...
[INFO] metadata stored in Supabase successfully
```

Or errors:
```
[ERROR] failed to store metadata in Supabase: <error details>
```

### Verify Data

```sql
-- Check recent uploads
SELECT 
  username,
  file_name,
  uploaded_at,
  gofile_url
FROM recordings
WHERE uploaded_at > NOW() - INTERVAL '1 hour'
ORDER BY uploaded_at DESC;

-- Check for missing data
SELECT 
  COUNT(*) as total,
  COUNT(gofile_url) as with_url,
  COUNT(md5) as with_md5
FROM recordings;
```

## Troubleshooting

### Error: "relation 'recordings' does not exist"

**Solution**: Run the migration SQL to create the table.

### Error: "new row violates row-level security policy"

**Solution**: Check RLS policies or use service_role key instead of anon key.

### Error: "Failed to store metadata in Supabase"

**Solutions**:
1. Verify Supabase URL is correct
2. Check API key is valid
3. Ensure table exists
4. Check network connectivity
5. Review Supabase logs in dashboard

### No Data Appearing

**Check**:
1. `SUPABASE_ENABLED=true` is set
2. GoFile upload succeeded first
3. No errors in GoondVR logs
4. Table name matches configuration
5. RLS policies allow inserts

## Cost Considerations

### Supabase Free Tier

- **Database**: 500 MB storage
- **Bandwidth**: 2 GB/month
- **API Requests**: Unlimited

### Estimated Usage

**Metadata per recording**: ~1 KB

**Examples**:
- 1,000 recordings = 1 MB
- 10,000 recordings = 10 MB
- 100,000 recordings = 100 MB

**Conclusion**: Free tier is sufficient for most users!

### Upgrading

If you exceed free tier:
- **Pro Plan**: $25/month
  - 8 GB database
  - 50 GB bandwidth
  - Daily backups

## Backup and Export

### Export All Data

```sql
-- Export to CSV (in SQL Editor)
COPY (SELECT * FROM recordings) TO STDOUT WITH CSV HEADER;
```

Or use Supabase dashboard:
1. Go to **Table Editor**
2. Select **recordings**
3. Click **Export** → **CSV**

### Backup Strategy

1. **Automatic**: Supabase Pro includes daily backups
2. **Manual**: Export CSV regularly
3. **Programmatic**: Use Supabase API to sync to S3

## Advanced Features

### Real-time Subscriptions

Get notified when new recordings are added:

```javascript
const subscription = supabase
  .channel('recordings')
  .on('postgres_changes', 
    { event: 'INSERT', schema: 'public', table: 'recordings' },
    (payload) => {
      console.log('New recording:', payload.new)
    }
  )
  .subscribe()
```

### Database Functions

Create custom functions for complex queries:

```sql
CREATE OR REPLACE FUNCTION get_channel_stats(channel_username TEXT)
RETURNS TABLE (
  total_recordings BIGINT,
  total_size_gb NUMERIC,
  total_hours NUMERIC,
  avg_viewers NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::BIGINT,
    (SUM(file_size) / 1024.0 / 1024.0 / 1024.0)::NUMERIC,
    (SUM(duration) / 3600.0)::NUMERIC,
    AVG(num_viewers)::NUMERIC
  FROM recordings
  WHERE username = channel_username;
END;
$$ LANGUAGE plpgsql;
```

### Webhooks

Trigger external services when recordings are added:

1. Go to **Database** → **Webhooks**
2. Create new webhook
3. Set trigger: `INSERT` on `recordings`
4. Set URL: Your webhook endpoint
5. Configure payload

## Integration Examples

### Discord Notifications

```javascript
// Supabase Edge Function
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { record } = await req.json()
  
  await fetch('YOUR_DISCORD_WEBHOOK_URL', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      content: `New recording: ${record.username} - ${record.file_name}`,
      embeds: [{
        title: record.room_title || 'New Recording',
        url: record.gofile_url,
        fields: [
          { name: 'Duration', value: `${(record.duration / 60).toFixed(1)} min` },
          { name: 'Size', value: `${(record.file_size / 1024 / 1024).toFixed(1)} MB` },
          { name: 'Viewers', value: record.num_viewers?.toString() || 'N/A' }
        ]
      }]
    })
  })
  
  return new Response('OK')
})
```

### Telegram Bot

Similar to Discord, send notifications to Telegram when new recordings are added.

## FAQ

**Q: Do I need Supabase?**
A: No, it's optional. GoFile links are also logged in the application.

**Q: Can I use my own PostgreSQL database?**
A: Yes, modify `uploader/supabase.go` to use your database connection.

**Q: What if Supabase is down?**
A: Recording and GoFile upload still work. Metadata storage will fail but won't affect recording.

**Q: Can I migrate existing recordings?**
A: Yes, write a script to parse logs and insert historical data.

**Q: Is my data private?**
A: Yes, with RLS enabled. Only authenticated users can access data.

## Support

For issues:
1. Check Supabase logs in dashboard
2. Verify API credentials
3. Test with SQL Editor
4. Review GoondVR logs
5. Open GitHub issue

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase JavaScript Client](https://supabase.com/docs/reference/javascript/introduction)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
