#!/bin/bash

# GoondVR AWS Deployment Script
# This script helps you deploy GoondVR to AWS with GoFile integration

set -e

echo "=========================================="
echo "GoondVR AWS Deployment Script"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first:"
    echo "   https://www.terraform.io/downloads"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first:"
    echo "   https://aws.amazon.com/cli/"
    exit 1
fi

echo "✓ Terraform found: $(terraform version | head -n1)"
echo "✓ AWS CLI found: $(aws --version)"
echo ""

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run:"
    echo "   aws configure"
    exit 1
fi

echo "✓ AWS credentials configured"
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
echo "  Account: $AWS_ACCOUNT"
echo "  Region: $AWS_REGION"
echo ""

# Navigate to terraform directory
cd "$(dirname "$0")/terraform"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo ""
    echo "⚠️  Please edit terraform.tfvars with your configuration:"
    echo "   - GoFile API token"
    echo "   - Admin password"
    echo "   - Allowed IP addresses"
    echo ""
    echo "Then run this script again."
    exit 0
fi

# Prompt for confirmation
echo "This will deploy GoondVR to AWS with the following configuration:"
echo ""
grep -E "^[^#]" terraform.tfvars | grep -v "password\|token" || true
echo ""
read -p "Do you want to proceed? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "=========================================="
echo "Initializing Terraform..."
echo "=========================================="
terraform init

echo ""
echo "=========================================="
echo "Planning deployment..."
echo "=========================================="
terraform plan -out=tfplan

echo ""
read -p "Review the plan above. Continue with deployment? (yes/no): " DEPLOY

if [ "$DEPLOY" != "yes" ]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

echo ""
echo "=========================================="
echo "Deploying to AWS..."
echo "=========================================="
terraform apply tfplan
rm -f tfplan

echo ""
echo "=========================================="
echo "✓ Deployment Complete!"
echo "=========================================="
echo ""

# Get outputs
ALB_URL=$(terraform output -raw alb_url 2>/dev/null || echo "")
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
LOG_GROUP=$(terraform output -raw cloudwatch_log_group 2>/dev/null || echo "")

if [ -n "$ALB_URL" ]; then
    echo "🌐 Web Interface: $ALB_URL"
    echo ""
    echo "Note: It may take 2-3 minutes for the service to become healthy."
    echo ""
fi

echo "📊 Useful Commands:"
echo ""
echo "View logs:"
echo "  aws logs tail $LOG_GROUP --follow"
echo ""
echo "Check service status:"
echo "  aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE"
echo ""
echo "Update service (after config changes):"
echo "  terraform apply"
echo ""
echo "Destroy all resources:"
echo "  terraform destroy"
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Wait 2-3 minutes for the service to start"
echo "2. Visit $ALB_URL"
echo "3. Log in with your admin credentials"
echo "4. Add channels via the web interface"
echo "5. Recordings will automatically upload to GoFile"
echo ""
echo "For more information, see aws/README.md"
echo ""
