# GoFile Integration Guide

This document explains how to use GoondVR with automatic GoFile.io uploads.

## Overview

GoondVR now supports automatic uploading of completed recordings to GoFile.io, a free file hosting service. This feature is particularly useful when:

- Running on AWS or cloud platforms with expensive storage
- You want off-site backup of recordings
- You need to share recordings easily
- You want to save local disk space

## Features

- ✅ Automatic upload after recording completes
- ✅ Optional local file deletion after successful upload
- ✅ Configurable via web UI or configuration file
- ✅ Per-recording upload status in logs
- ✅ Support for large files (GoFile supports up to 5GB per file)
- ✅ Folder organization support

## Getting Started

### 1. Get GoFile API Token

1. Visit [GoFile.io](https://gofile.io)
2. Create a free account
3. Go to your profile settings
4. Generate an API token
5. Copy the token for later use

### 2. (Optional) Create a Folder

1. Log in to GoFile
2. Create a folder for your recordings
3. Note the folder ID from the URL (e.g., `https://gofile.io/d/FOLDER_ID`)

### 3. Configure GoondVR

#### Option A: Web UI Configuration

1. Open GoondVR web interface
2. Navigate to **Settings**
3. Scroll to **GoFile Upload Settings**
4. Configure:
   - **Enable GoFile**: Check this box
   - **API Token**: Paste your GoFile API token
   - **Folder ID**: (Optional) Enter folder ID
   - **Delete After Upload**: Check to remove local files after upload
5. Click **Save Settings**

#### Option B: Configuration File

Edit `conf/settings.json`:

```json
{
  "gofile_enabled": true,
  "gofile_api_token": "your-api-token-here",
  "gofile_folder_id": "",
  "gofile_delete_after_upload": true
}
```

#### Option C: Command Line

```bash
./goondvr \
  --gofile-enabled \
  --gofile-api-token "your-token" \
  --gofile-folder-id "optional-folder-id" \
  --gofile-delete-after-upload
```

#### Option D: Environment Variables (Docker/AWS)

```bash
export GOFILE_ENABLED=true
export GOFILE_API_TOKEN="your-token"
export GOFILE_FOLDER_ID=""
export GOFILE_DELETE_AFTER_UPLOAD=true

./goondvr
```

Or in Docker:

```bash
docker run -d \
  -e GOFILE_ENABLED=true \
  -e GOFILE_API_TOKEN="your-token" \
  -e GOFILE_DELETE_AFTER_UPLOAD=true \
  -p 8080:8080 \
  -v ./videos:/usr/src/app/videos \
  -v ./conf:/usr/src/app/conf \
  ghcr.io/heapofchaos/goondvr:latest
```

## How It Works

### Upload Process

1. **Recording Starts**: When a channel goes online, recording begins
2. **Recording Stops**: When channel goes offline, recording stops
3. **Finalization**: File is processed (remux/transcode if configured)
4. **Upload**: File is automatically uploaded to GoFile
5. **Cleanup**: If enabled, local file is deleted after successful upload
6. **Logging**: Upload status and download link are logged

### Upload Flow

```
Channel Online → Record → Channel Offline → Finalize → Upload to GoFile → (Optional) Delete Local
```

### File Processing Order

1. **Raw Recording**: `.ts` or `.mp4` file created during recording
2. **Finalization** (if enabled):
   - `none`: No processing, upload as-is
   - `remux`: Remux to MP4 with better seeking
   - `transcode`: Re-encode video for smaller size
3. **Move to Completed**: File moved to completed directory (if configured)
4. **Upload**: File uploaded to GoFile
5. **Delete**: Local file deleted (if enabled)

## Configuration Options

### gofile_enabled

- **Type**: Boolean
- **Default**: `false`
- **Description**: Enable or disable GoFile uploads

### gofile_api_token

- **Type**: String
- **Required**: Yes (when enabled)
- **Description**: Your GoFile API token for authentication

### gofile_folder_id

- **Type**: String
- **Optional**: Yes
- **Description**: Specific folder ID to upload files to. If empty, files go to root.

### gofile_delete_after_upload

- **Type**: Boolean
- **Default**: `false`
- **Description**: Delete local file after successful upload to save disk space

## Monitoring Uploads

### Via Web UI

1. Open the channel details
2. View the logs section
3. Look for upload status messages:
   - `uploading to GoFile: filename.mp4`
   - `uploaded to GoFile: https://gofile.io/d/...`
   - `uploaded and deleted local file: filename.mp4`

### Via Logs

```bash
# Docker
docker logs goondvr

# AWS CloudWatch
aws logs tail /ecs/goondvr --follow

# Local
# Check console output
```

### Upload Status Messages

- ✅ `uploading to GoFile: filename.mp4` - Upload started
- ✅ `uploaded to GoFile: https://gofile.io/d/ABC123` - Upload successful
- ✅ `uploaded and deleted local file: filename.mp4` - Upload and cleanup successful
- ❌ `gofile upload failed: error message` - Upload failed, file kept locally

## Troubleshooting

### Upload Fails

**Symptom**: Error message in logs: `gofile upload failed`

**Solutions**:
1. Verify API token is correct
2. Check internet connectivity
3. Ensure file size is under GoFile limits (5GB per file)
4. Check GoFile service status
5. Verify account is in good standing

### Files Not Uploading

**Symptom**: No upload messages in logs

**Solutions**:
1. Verify `gofile_enabled` is `true`
2. Check API token is set
3. Ensure recording completed successfully
4. Check finalization didn't fail

### Local Files Not Deleted

**Symptom**: Files remain after upload

**Solutions**:
1. Verify `gofile_delete_after_upload` is `true`
2. Check upload completed successfully
3. Verify file permissions allow deletion

### Slow Uploads

**Symptom**: Uploads take a long time

**Solutions**:
1. Check your internet upload speed
2. Consider reducing recording quality
3. Enable transcoding to reduce file size
4. Use finalize mode `transcode` with higher CRF value

## Best Practices

### 1. Test First

Start with one channel and verify uploads work before adding more channels.

### 2. Monitor Disk Space

If not deleting after upload, monitor disk usage:
- Set up disk space alerts
- Configure `completed_dir` on separate volume
- Enable `gofile_delete_after_upload` for production

### 3. Organize with Folders

Create separate folders for:
- Different channels
- Different sites (Chaturbate vs Stripchat)
- Different time periods

### 4. Backup Configuration

Regularly backup:
- `conf/settings.json`
- `conf/channels.json`

### 5. Use Finalization

Enable `finalize_mode` for better files:
- `remux`: Better seeking, same quality, minimal processing
- `transcode`: Smaller files, configurable quality

Example settings:
```json
{
  "finalize_mode": "remux",
  "ffmpeg_container": "mp4",
  "gofile_enabled": true,
  "gofile_delete_after_upload": true
}
```

### 6. Security

- Keep API token secret
- Don't commit tokens to version control
- Use environment variables in production
- Rotate tokens periodically

## AWS Deployment

For AWS deployment with GoFile integration, see [aws/README.md](aws/README.md).

Quick start:
```bash
cd aws/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GoFile token
terraform init
terraform apply
```

## Cost Considerations

### GoFile

- **Free Tier**: Unlimited storage, 5GB per file
- **Premium**: Faster speeds, no ads, custom domains

### Storage Savings

With `gofile_delete_after_upload` enabled:

**Example**: 10 channels, 2 hours/day each, 1080p
- Recording size: ~2GB per hour
- Daily recordings: 10 channels × 2 hours × 2GB = 40GB/day
- Monthly: 40GB × 30 = 1.2TB/month

**Without GoFile**: Need 1.2TB+ local storage
**With GoFile + Delete**: Only need temporary storage (~40GB)

**AWS EFS Savings**: 1.2TB × $0.30/GB = $360/month saved!

## Limitations

1. **File Size**: GoFile free tier supports up to 5GB per file
   - Use `max_filesize` to split large recordings
   - Example: `--max-filesize 4096` (4GB chunks)

2. **Upload Speed**: Limited by your internet connection
   - Consider transcoding for smaller files
   - Use lower resolution if needed

3. **API Rate Limits**: GoFile may have rate limits
   - Uploads are sequential per channel
   - Multiple channels upload in parallel

4. **Network Dependency**: Requires stable internet
   - Failed uploads keep local file
   - Can retry manually if needed

## Manual Upload

If automatic upload fails, you can manually upload:

```bash
# Using the uploader directly (after building)
go run uploader/gofile.go /path/to/video.mp4
```

Or use GoFile web interface to upload manually.

## FAQ

**Q: What happens if upload fails?**
A: The local file is kept and an error is logged. You can retry manually.

**Q: Can I upload to multiple folders?**
A: Not automatically. You'd need to configure different folder IDs per channel (feature request).

**Q: Does this work with Stripchat?**
A: Yes! Works with both Chaturbate and Stripchat recordings.

**Q: Can I disable upload for specific channels?**
A: Currently it's a global setting. You can pause channels you don't want to upload.

**Q: What if I run out of GoFile storage?**
A: GoFile free tier has unlimited storage. Premium offers additional features.

**Q: Can I use other upload services?**
A: Currently only GoFile is supported. Other services can be added (feature request).

## Support

For issues:
1. Check logs for error messages
2. Verify configuration is correct
3. Test with a small file first
4. Check [GoFile API status](https://gofile.io)
5. Open an issue on GitHub with logs

## Contributing

Want to add support for other upload services? PRs welcome!

Potential services:
- Google Drive
- Dropbox
- AWS S3
- Mega.nz
- File.io

See `uploader/gofile.go` as a reference implementation.
