# GoondVR with GoFile Integration & AWS Deployment

This enhanced version of GoondVR adds automatic file uploads to GoFile.io and complete AWS deployment infrastructure.

## 🎯 New Features

### 1. GoFile.io Integration
- ✅ Automatic upload of completed recordings to GoFile
- ✅ Optional local file deletion after upload (save disk space)
- ✅ Configurable via Web UI, config file, CLI, or environment variables
- ✅ Upload status tracking in channel logs
- ✅ Support for folder organization

### 2. AWS Deployment
- ✅ Complete Terraform infrastructure as code
- ✅ ECS Fargate deployment (serverless containers)
- ✅ EFS for persistent storage
- ✅ Application Load Balancer for public access
- ✅ CloudWatch logging and monitoring
- ✅ Secrets Manager for sensitive configuration
- ✅ Auto-scaling ready

## 🚀 Quick Start

### Option 1: Docker with GoFile (Recommended for Testing)

1. **Get GoFile API Token**
   - Visit [GoFile.io](https://gofile.io)
   - Create account and generate API token

2. **Configure**
   ```bash
   cp .env.example .env
   # Edit .env with your GoFile token
   ```

3. **Run**
   ```bash
   docker-compose -f docker-compose.gofile.yml up -d
   ```

4. **Access**
   - Open http://localhost:8080
   - Add channels via web UI
   - Recordings automatically upload to GoFile

### Option 2: AWS Deployment (Recommended for Production)

1. **Prerequisites**
   - AWS Account
   - Terraform installed
   - AWS CLI configured
   - GoFile API token

2. **Deploy**
   ```bash
   cd aws/terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your configuration
   terraform init
   terraform apply
   ```

3. **Access**
   - Get URL: `terraform output alb_url`
   - Open in browser
   - Configure channels

See [aws/README.md](aws/README.md) for detailed AWS deployment guide.

## 📋 Configuration

### GoFile Settings

Configure via any of these methods:

#### Web UI
1. Navigate to Settings
2. Scroll to "GoFile Upload Settings"
3. Enable and configure

#### Configuration File (`conf/settings.json`)
```json
{
  "gofile_enabled": true,
  "gofile_api_token": "your-token",
  "gofile_folder_id": "",
  "gofile_delete_after_upload": true
}
```

#### Environment Variables
```bash
export GOFILE_ENABLED=true
export GOFILE_API_TOKEN="your-token"
export GOFILE_DELETE_AFTER_UPLOAD=true
```

#### Command Line
```bash
./goondvr \
  --gofile-enabled \
  --gofile-api-token "your-token" \
  --gofile-delete-after-upload
```

## 📁 Project Structure

```
.
├── uploader/
│   └── gofile.go              # GoFile upload implementation
├── aws/
│   ├── terraform/             # AWS infrastructure as code
│   │   ├── main.tf           # Main Terraform configuration
│   │   ├── variables.tf      # Variable definitions
│   │   ├── outputs.tf        # Output values
│   │   └── terraform.tfvars.example
│   ├── README.md             # AWS deployment guide
│   ├── deploy.sh             # Automated deployment script
│   ├── sample-channels.json  # Example channel configuration
│   └── sample-settings.json  # Example settings with GoFile
├── docker-compose.gofile.yml # Docker Compose with GoFile
├── .env.example              # Environment variables template
├── GOFILE_INTEGRATION.md     # GoFile integration guide
└── README_GOFILE_AWS.md      # This file
```

## 🔧 Multi-Channel Setup

### Via Web UI
1. Open web interface
2. Click "Add Channel"
3. Enter channel details
4. Repeat for each channel

### Via Configuration File
1. Edit `conf/channels.json`:
```json
[
  {
    "username": "channel1",
    "site": "chaturbate",
    "resolution": 1080,
    "framerate": 30
  },
  {
    "username": "channel2",
    "site": "stripchat",
    "resolution": 1080,
    "framerate": 30
  }
]
```

2. Restart application

### Resource Requirements

Per concurrent recording:
- **CPU**: 0.5 vCPU
- **Memory**: 1 GB RAM
- **Storage**: 2-4 GB/hour (depends on quality)

**Examples:**
- 5 channels: 2 vCPU, 4 GB RAM
- 10 channels: 4 vCPU, 8 GB RAM
- 20 channels: 8 vCPU, 16 GB RAM

## 💰 Cost Optimization

### With GoFile + Delete After Upload

**Scenario**: 10 channels, 2 hours/day each, 1080p

**Without GoFile:**
- Storage needed: 1.2 TB/month
- AWS EFS cost: ~$360/month

**With GoFile:**
- Temporary storage: ~40 GB
- AWS EFS cost: ~$12/month
- **Savings: $348/month** 💰

### GoFile Pricing
- **Free**: Unlimited storage, 5GB per file
- **Premium**: Faster speeds, no ads

## 📊 Monitoring

### Docker
```bash
# View logs
docker logs -f goondvr-gofile

# Check status
docker ps
```

### AWS
```bash
# View logs
aws logs tail /ecs/goondvr --follow

# Check service
aws ecs describe-services \
  --cluster goondvr-cluster \
  --services goondvr-service

# Check task status
aws ecs list-tasks --cluster goondvr-cluster
```

### Web UI
- View channel logs for upload status
- Monitor disk usage
- Check recording status

## 🔒 Security Best Practices

1. **Restrict Access**
   - Use specific IPs in `allowed_cidr_blocks`
   - Enable admin authentication
   - Use strong passwords

2. **Secrets Management**
   - Never commit tokens to git
   - Use environment variables
   - Rotate tokens periodically

3. **Network Security**
   - Use HTTPS (add ACM certificate to ALB)
   - Enable VPC endpoints for AWS services
   - Use security groups properly

4. **Monitoring**
   - Enable CloudWatch alarms
   - Monitor upload failures
   - Track disk usage

## 🐛 Troubleshooting

### GoFile Upload Fails
1. Verify API token is correct
2. Check internet connectivity
3. Ensure file size < 5GB
4. Check logs for error details

### AWS Service Won't Start
1. Check CloudWatch logs
2. Verify EFS mount is healthy
3. Check security groups
4. Ensure sufficient CPU/memory

### High Costs
1. Enable `gofile_delete_after_upload`
2. Reduce recording quality
3. Use EFS lifecycle policies
4. Monitor and optimize resources

## 📚 Documentation

- [GoFile Integration Guide](GOFILE_INTEGRATION.md) - Detailed GoFile setup
- [AWS Deployment Guide](aws/README.md) - Complete AWS deployment
- [Original README](README.md) - Base GoondVR documentation

## 🎯 Use Cases

### 1. Personal Archive
- Record favorite channels
- Auto-upload to GoFile
- Delete local copies
- Access from anywhere

### 2. Multi-Channel Recording
- Monitor multiple channels
- Automatic recording when online
- Centralized storage on GoFile
- Minimal local storage needed

### 3. Cloud Recording Service
- Deploy on AWS
- Scale to many channels
- Cost-effective with GoFile
- Professional monitoring

### 4. Backup Solution
- Keep local copies
- Upload to GoFile as backup
- Redundant storage
- Easy sharing

## 🔄 Workflow

```
Channel Online
    ↓
Start Recording
    ↓
Channel Offline
    ↓
Stop Recording
    ↓
Finalize (remux/transcode)
    ↓
Upload to GoFile
    ↓
(Optional) Delete Local File
    ↓
Log Download Link
```

## 🚦 Getting Started Checklist

- [ ] Get GoFile API token
- [ ] Choose deployment method (Docker/AWS)
- [ ] Configure settings
- [ ] Add channels
- [ ] Test with one channel
- [ ] Monitor first recording
- [ ] Verify upload to GoFile
- [ ] Scale to more channels

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- [ ] Support for other upload services (S3, Google Drive, etc.)
- [ ] Per-channel upload configuration
- [ ] Upload retry logic
- [ ] Bandwidth throttling
- [ ] Upload queue management
- [ ] Web UI for upload history

## 📝 License

Same as original GoondVR project.

## 🙏 Credits

- Original GoondVR by [HeapOfChaos](https://github.com/HeapOfChaos/goondvr)
- GoFile.io for file hosting
- AWS for cloud infrastructure

## 📞 Support

- Check documentation first
- Review logs for errors
- Open GitHub issue with details
- Include configuration (redact tokens!)

## 🎉 Success Stories

Share your setup:
- How many channels?
- AWS or Docker?
- Storage savings?
- Any tips?

Open a discussion on GitHub!
