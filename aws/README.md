# GoondVR AWS Deployment with GoFile Integration

This guide will help you deploy GoondVR on AWS with automatic uploads to GoFile.io for multiple channels.

## Features

- **AWS ECS Fargate**: Serverless container deployment
- **EFS Storage**: Persistent storage for recordings and configuration
- **Application Load Balancer**: Public access to web UI
- **GoFile Integration**: Automatic upload of completed recordings
- **Multi-Channel Support**: Record multiple channels simultaneously
- **Auto-scaling**: Can be configured for multiple tasks
- **CloudWatch Logs**: Centralized logging

## Architecture

```
Internet → ALB → ECS Fargate Task → EFS Storage
                      ↓
                  GoFile.io (uploads)
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (v1.0+)
3. **GoFile.io Account** and API token
4. **AWS CLI** configured with credentials

## Getting Your GoFile API Token

1. Go to [GoFile.io](https://gofile.io)
2. Create an account or log in
3. Navigate to your profile settings
4. Generate an API token
5. (Optional) Create a folder and note the folder ID

## Deployment Steps

### 1. Clone and Prepare

```bash
cd aws/terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Variables

Edit `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"
project_name = "goondvr"

# ECS Task Configuration
task_cpu = "2048"     # 2 vCPU (increase for more channels)
task_memory = "4096"  # 4 GB RAM (increase for more channels)

# GoFile Configuration
gofile_api_token = "your-actual-gofile-token"
gofile_folder_id = ""  # Optional
gofile_delete_after_upload = true

# Web UI Authentication
admin_username = "admin"
admin_password = "your-secure-password"

# Security (recommended: restrict to your IP)
allowed_cidr_blocks = ["YOUR_IP/32"]
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy
terraform apply
```

This will create:
- VPC with public subnets
- ECS Fargate cluster and service
- Application Load Balancer
- EFS file system for persistent storage
- CloudWatch log groups
- Security groups and IAM roles

### 4. Get the Application URL

After deployment completes:

```bash
terraform output alb_url
```

Visit the URL in your browser to access the GoondVR web interface.

### 5. Configure Channels

#### Option A: Via Web UI

1. Open the ALB URL in your browser
2. Log in with your admin credentials
3. Click "Add Channel"
4. Enter channel details:
   - Username
   - Site (Chaturbate or Stripchat)
   - Resolution (1080p recommended)
   - Framerate (30 fps recommended)

#### Option B: Pre-configure Channels

1. Edit `sample-channels.json` with your channels:

```json
[
  {
    "is_paused": false,
    "username": "your_channel_1",
    "site": "chaturbate",
    "framerate": 30,
    "resolution": 1080,
    "pattern": "videos/{{if ne .Site \"chaturbate\"}}{{.Site}}/{{end}}{{.Username}}_{{.Year}}-{{.Month}}-{{.Day}}_{{.Hour}}-{{.Minute}}-{{.Second}}{{if .Sequence}}_{{.Sequence}}{{end}}",
    "max_duration": 0,
    "max_filesize": 0,
    "created_at": 0
  }
]
```

2. Upload to EFS:

```bash
# Get ECS task ID
TASK_ID=$(aws ecs list-tasks --cluster goondvr-cluster --service goondvr-service --query 'taskArns[0]' --output text | cut -d'/' -f3)

# Copy configuration
aws ecs execute-command \
  --cluster goondvr-cluster \
  --task $TASK_ID \
  --container goondvr \
  --interactive \
  --command "/bin/sh"

# Then inside the container:
# Upload your channels.json to /usr/src/app/conf/channels.json
```

Or use AWS Systems Manager Session Manager to access the EFS and upload files.

## GoFile Configuration

### Settings via Web UI

1. Navigate to Settings in the web interface
2. Scroll to "GoFile Upload Settings"
3. Configure:
   - **Enable GoFile**: Check to enable uploads
   - **API Token**: Your GoFile API token
   - **Folder ID**: (Optional) Specific folder
   - **Delete After Upload**: Check to save disk space

### How It Works

1. Channel goes online → Recording starts
2. Channel goes offline → Recording stops
3. File is finalized (remuxed/transcoded if configured)
4. File is automatically uploaded to GoFile
5. If "Delete After Upload" is enabled, local file is removed
6. Upload link is logged in the channel logs

## Resource Sizing

### For Multiple Channels

Recommended resources per concurrent recording:
- **CPU**: 512 units (0.5 vCPU) per channel
- **Memory**: 1024 MB per channel

Examples:
- **5 channels**: 2048 CPU (2 vCPU), 4096 MB RAM
- **10 channels**: 4096 CPU (4 vCPU), 8192 MB RAM
- **20 channels**: 8192 CPU (8 vCPU), 16384 MB RAM

Update in `terraform.tfvars`:
```hcl
task_cpu = "4096"    # For ~10 channels
task_memory = "8192"
```

Then apply changes:
```bash
terraform apply
```

## Monitoring

### CloudWatch Logs

View logs:
```bash
aws logs tail /ecs/goondvr --follow
```

### ECS Service Status

```bash
aws ecs describe-services \
  --cluster goondvr-cluster \
  --services goondvr-service
```

### Check Recordings

```bash
# List EFS contents
aws efs describe-file-systems --query 'FileSystems[?Name==`goondvr-efs`]'
```

## Cost Estimation

Monthly costs (us-east-1):
- **ECS Fargate** (2 vCPU, 4GB RAM, 24/7): ~$60
- **EFS Storage** (100 GB): ~$30
- **Application Load Balancer**: ~$20
- **Data Transfer**: Variable (depends on recording volume)
- **CloudWatch Logs**: ~$5

**Total**: ~$115/month + data transfer

### Cost Optimization

1. **Use GoFile Delete After Upload**: Reduces EFS storage costs
2. **EFS Lifecycle Policy**: Automatically moves old files to cheaper storage (already configured)
3. **Spot Instances**: Not available for Fargate, but can use EC2 with ECS
4. **Schedule Recording**: Stop service during off-hours if applicable

## Troubleshooting

### Service Won't Start

Check logs:
```bash
aws logs tail /ecs/goondvr --follow
```

Common issues:
- Insufficient CPU/memory for number of channels
- EFS mount issues
- Invalid GoFile API token

### GoFile Upload Fails

1. Check API token is valid
2. Verify internet connectivity from ECS task
3. Check CloudWatch logs for error messages
4. Ensure file size is within GoFile limits

### Can't Access Web UI

1. Check security group allows your IP:
```bash
aws ec2 describe-security-groups --group-ids <sg-id>
```

2. Verify ALB is healthy:
```bash
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

### High Costs

1. Check EFS storage usage:
```bash
aws efs describe-file-systems --file-system-id <fs-id>
```

2. Enable "Delete After Upload" to reduce storage
3. Consider reducing retention or recording quality

## Updating the Application

### Update Docker Image

1. Edit `terraform.tfvars`:
```hcl
docker_image = "ghcr.io/heapofchaos/goondvr:latest"
```

2. Apply changes:
```bash
terraform apply
```

ECS will perform a rolling update.

### Update Configuration

Settings are persisted in EFS at `/conf/settings.json` and `/conf/channels.json`.

## Backup and Recovery

### Backup Configuration

```bash
# Backup channels and settings
aws efs create-backup \
  --file-system-id <efs-id> \
  --tags Key=Name,Value=goondvr-backup
```

### Restore from Backup

1. Create new EFS from backup
2. Update Terraform to use new EFS ID
3. Apply changes

## Security Best Practices

1. **Restrict Access**: Use specific IP in `allowed_cidr_blocks`
2. **Strong Passwords**: Use complex admin password
3. **HTTPS**: Add ACM certificate to ALB (not included in basic setup)
4. **Secrets Rotation**: Rotate GoFile API token periodically
5. **VPC Endpoints**: Add for AWS services to avoid internet routing

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete:
- All recordings in EFS
- All configuration
- All AWS resources

Backup important data before destroying!

## Advanced Configuration

### Enable HTTPS

1. Request ACM certificate
2. Add HTTPS listener to ALB
3. Update security group for port 443

### Multiple Environments

Use Terraform workspaces:
```bash
terraform workspace new production
terraform workspace new staging
```

### Auto-scaling

Add auto-scaling to handle variable load:
```hcl
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.goondvr.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

## Support

For issues:
1. Check CloudWatch logs
2. Review [GoondVR GitHub](https://github.com/HeapOfChaos/goondvr)
3. Check [GoFile API docs](https://gofile.io/api)

## License

This deployment configuration is provided as-is. GoondVR is licensed under its original license.
