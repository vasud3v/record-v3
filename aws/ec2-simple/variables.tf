variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "goondvr"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m7i-flex.large"  # 2 vCPU, 8 GB RAM
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change to your IP for better security
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}

variable "gofile_api_token" {
  description = "GoFile API token"
  type        = string
  sensitive   = true
}

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  default     = ""
}

variable "supabase_api_key" {
  description = "Supabase API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for notifications"
  type        = string
  default     = ""
}

variable "admin_username" {
  description = "Admin username for web UI"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Admin password for web UI"
  type        = string
  sensitive   = true
}

variable "chaturbate_cookies" {
  description = "Chaturbate cookies for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "user_agent" {
  description = "User agent string"
  type        = string
  default     = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Brave/1 Mobile/15E148 Safari/E7FBAF"
}
