# GoondVR - Complete Setup with GoFile & Supabase

## 🎯 What This Does

Automatically records livestreams in **highest quality** (1080p60fps), uploads to **GoFile**, stores links in **Supabase**, and **deletes local files** to save space.

## ✨ Key Features

- ✅ **Highest Quality Recording**: 1080p @ 60fps by default
- ✅ **Automatic GoFile Upload**: Files uploaded immediately after recording
- ✅ **Supabase Integration**: All GoFile links stored in searchable database
- ✅ **Auto-Delete Local Files**: Save disk space (files deleted after upload)
- ✅ **Multi-Channel Support**: Record multiple channels simultaneously
- ✅ **AWS Deployment Ready**: Complete Terraform infrastructure
- ✅ **Docker Support**: Easy local deployment

## 🚀 Quick Start

### Prerequisites

1. **GoFile Account** - [Sign up](https://gofile.io) and get API token
2. **Supabase Account** - [Sign up](https://supabase.com) and create project
3. **Docker** (for local) or **AWS Account** (for cloud)

### Option 1: Docker (Local Testing)

```bash
# 1. Clone repository
git clone <repository-url>
cd goondvr

# 2. Configure environment
cp .env.example .env
# Edit .env with your credentials

# 3. Setup Supabase database
# - Go to your Supabase project
# - Run SQL from supabase/migrations/001_create_recordings_table.sql

# 4. Start application
docker-compose -f docker-compose.gofile.yml up -d

# 5. Access web UI
open http://localhost:8080
```

### Option 2: AWS (Production)

```bash
# 1. Setup Supabase
# - Create project at supabase.com
# - Run migration SQL
# - Get URL and API key

# 2. Configure AWS deployment
cd aws/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with all credentials

# 3. Deploy
terraform init
terraform apply

# 4. Get URL
terraform output alb_url
```

## 📋 Configuration

### Required Credentials

#### GoFile
1. Go to [gofile.io](https://gofile.io)
2. Create account
3. Profile → Generate API Token
4. Copy token

#### Supabase
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Settings → API
4. Copy:
   - Project URL
   - anon public key

### Environment Variables

```bash
# GoFile
GOFILE_ENABLED=true
GOFILE_API_TOKEN=your_token_here
GOFILE_FOLDER_ID=                    # Optional
GOFILE_DELETE_AFTER_UPLOAD=true     # Delete after upload

# Supabase
SUPABASE_ENABLED=true
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_API_KEY=your_key_here
SUPABASE_TABLE_NAME=recordings

# Admin
ADMIN_USERNAME=admin
ADMIN_PASSWORD=secure_password_here
```

## 🎬 How It Works

```
1. Channel goes online
   ↓
2. Start recording (1080p60fps)
   ↓
3. Channel goes offline
   ↓
4. Finalize recording (remux to MP4)
   ↓
5. Upload to GoFile
   ↓
6. Store metadata in Supabase
   ├─ GoFile download link
   ├─ File details
   ├─ Recording metadata
   └─ Channel info
   ↓
7. Delete local file
   ↓
8. Ready for next recording
```

## 📊 Supabase Database

### What Gets Stored

For each recording:
- GoFile download URL
- Channel username and site
- File size and duration
- Resolution and framerate
- Recording timestamp
- Viewer count
- Room title
- MD5 hash

### Querying Your Recordings

```sql
-- Get all recordings for a channel
SELECT * FROM recordings 
WHERE username = 'channel1' 
ORDER BY recorded_at DESC;

-- Get total storage per channel
SELECT 
  username,
  COUNT(*) as recordings,
  SUM(file_size) / 1024 / 1024 / 1024 as total_gb
FROM recordings
GROUP BY username;

-- Get recent recordings
SELECT 
  username,
  file_name,
  gofile_url,
  recorded_at
FROM recordings
WHERE recorded_at > NOW() - INTERVAL '7 days'
ORDER BY recorded_at DESC;
```

## 🎛️ Adding Channels

### Via Web UI

1. Open web interface
2. Click "Add Channel"
3. Enter:
   - Username
   - Site (Chaturbate/Stripchat)
   - Resolution: 1080
   - Framerate: 60
4. Click "Add"

### Via Configuration File

Edit `conf/channels.json`:

```json
[
  {
    "username": "channel1",
    "site": "chaturbate",
    "framerate": 60,
    "resolution": 1080,
    "is_paused": false
  },
  {
    "username": "channel2",
    "site": "stripchat",
    "framerate": 60,
    "resolution": 1080,
    "is_paused": false
  }
]
```

## 💰 Cost Analysis

### Without This Setup
- **Local Storage**: 1.2 TB/month for 10 channels
- **Cost**: $360/month (AWS EFS) or expensive local drives

### With This Setup
- **GoFile**: Free (unlimited storage)
- **Supabase**: Free (up to 500MB metadata)
- **AWS EFS**: ~$12/month (temporary storage only)
- **Total Savings**: $348/month! 💰

## 📈 Scaling

### Resource Requirements

Per concurrent recording:
- CPU: 0.5 vCPU
- Memory: 1 GB RAM
- Temporary Storage: 2-4 GB

### Examples

| Channels | CPU | RAM | AWS Cost/Month |
|----------|-----|-----|----------------|
| 5 | 2 vCPU | 4 GB | ~$75 |
| 10 | 4 vCPU | 8 GB | ~$130 |
| 20 | 8 vCPU | 16 GB | ~$240 |

## 🔍 Monitoring

### Check Logs

**Docker:**
```bash
docker logs -f goondvr-gofile
```

**AWS:**
```bash
aws logs tail /ecs/goondvr --follow
```

### Look For

✅ Success messages:
```
[INFO] uploading to GoFile: filename.mp4
[INFO] uploaded to GoFile: https://gofile.io/d/ABC123
[INFO] storing metadata in Supabase...
[INFO] metadata stored in Supabase successfully
[INFO] deleted local file: filename.mp4
```

❌ Error messages:
```
[ERROR] gofile upload failed: <reason>
[ERROR] failed to store metadata in Supabase: <reason>
```

### Verify in Supabase

1. Go to Supabase dashboard
2. Table Editor → recordings
3. See all uploaded recordings with GoFile links

## 🛠️ Troubleshooting

### Upload Fails

**Check:**
1. GoFile API token is valid
2. Internet connectivity
3. File size < 5GB (GoFile limit)

**Solution:**
- Verify token in GoFile dashboard
- Test with: `curl https://api.gofile.io/servers`
- Use `max_filesize` to split large recordings

### Supabase Errors

**Check:**
1. Supabase URL is correct
2. API key is valid
3. Table exists
4. RLS policies allow inserts

**Solution:**
- Re-run migration SQL
- Use service_role key instead of anon key
- Check Supabase logs

### Local Files Not Deleted

**Check:**
1. `GOFILE_DELETE_AFTER_UPLOAD=true`
2. Upload succeeded
3. File permissions

**Solution:**
- Check logs for upload success
- Verify file ownership
- Check disk space

## 🔒 Security

### Best Practices

1. **Use Strong Passwords**
   ```bash
   ADMIN_PASSWORD=$(openssl rand -base64 32)
   ```

2. **Restrict AWS Access**
   ```hcl
   allowed_cidr_blocks = ["YOUR_IP/32"]
   ```

3. **Use Supabase RLS**
   - Enable Row Level Security
   - Restrict access to authenticated users

4. **Rotate Credentials**
   - Change GoFile token quarterly
   - Rotate Supabase keys annually

5. **Enable HTTPS**
   - Add ACM certificate to ALB
   - Force HTTPS redirects

## 📚 Documentation

- **[SUPABASE_SETUP.md](SUPABASE_SETUP.md)** - Detailed Supabase guide
- **[GOFILE_INTEGRATION.md](GOFILE_INTEGRATION.md)** - GoFile integration details
- **[aws/README.md](aws/README.md)** - Complete AWS deployment guide
- **[README.md](README.md)** - Original GoondVR documentation

## 🎓 Advanced Usage

### Custom Queries

Build a dashboard to:
- View all recordings
- Search by date/channel
- Track storage usage
- Monitor viewer counts
- Export data

### Webhooks

Trigger actions when recordings complete:
- Send Discord notifications
- Update external databases
- Trigger video processing
- Generate thumbnails

### API Integration

Use Supabase API to:
- Build mobile apps
- Create custom dashboards
- Integrate with other services
- Automate workflows

## 🤝 Contributing

Want to improve this?

**Ideas:**
- Support for other upload services (S3, Google Drive)
- Automatic thumbnail generation
- Video transcoding options
- Mobile app
- Better analytics dashboard

## ❓ FAQ

**Q: Why 60fps instead of 30fps?**
A: Highest quality available. Streams that don't support 60fps will record at their maximum.

**Q: What if GoFile is down?**
A: Recording continues, file is kept locally, upload can be retried.

**Q: Can I keep local copies?**
A: Yes, set `GOFILE_DELETE_AFTER_UPLOAD=false`

**Q: How long do GoFile links last?**
A: GoFile free tier keeps files indefinitely (with occasional access).

**Q: Can I use my own storage?**
A: Yes, modify `uploader/gofile.go` to support other services.

**Q: Is this legal?**
A: Recording public streams for personal use is generally legal. Check your local laws.

## 📞 Support

**Issues:**
1. Check logs first
2. Verify all credentials
3. Test with one channel
4. Review documentation
5. Open GitHub issue with logs

**Resources:**
- [GoFile API Docs](https://gofile.io/api)
- [Supabase Docs](https://supabase.com/docs)
- [AWS ECS Docs](https://docs.aws.amazon.com/ecs/)

## 🎉 Success Checklist

- [ ] GoFile account created and API token obtained
- [ ] Supabase project created and database migrated
- [ ] Environment variables configured
- [ ] Application deployed (Docker or AWS)
- [ ] Test channel added
- [ ] First recording completed
- [ ] GoFile upload verified
- [ ] Supabase entry confirmed
- [ ] Local file deleted
- [ ] Ready to scale!

## 📄 License

Same as original GoondVR project.

## 🙏 Credits

- Original GoondVR by [HeapOfChaos](https://github.com/HeapOfChaos/goondvr)
- GoFile.io for free file hosting
- Supabase for database platform
- AWS for cloud infrastructure

---

**Ready to start?** Follow the Quick Start guide above! 🚀
