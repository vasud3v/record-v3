variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "goondvr"
}

variable "docker_image" {
  description = "Docker image to use for the ECS task"
  type        = string
  default     = "ghcr.io/heapofchaos/goondvr:latest"
}

variable "task_cpu" {
  description = "CPU units for the ECS task (1024 = 1 vCPU)"
  type        = string
  default     = "2048"
}

variable "task_memory" {
  description = "Memory for the ECS task in MB"
  type        = string
  default     = "4096"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "gofile_api_token" {
  description = "GoFile API token for uploads"
  type        = string
  sensitive   = true
}

variable "gofile_folder_id" {
  description = "GoFile folder ID to upload files to"
  type        = string
  default     = ""
}

variable "gofile_delete_after_upload" {
  description = "Delete local files after successful upload to GoFile"
  type        = bool
  default     = true
}

variable "admin_username" {
  description = "Admin username for web UI authentication"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Admin password for web UI authentication"
  type        = string
  sensitive   = true
}

variable "supabase_enabled" {
  description = "Enable Supabase integration for storing recording metadata"
  type        = bool
  default     = true
}

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_api_key" {
  description = "Supabase API key (anon or service role)"
  type        = string
  sensitive   = true
}

variable "supabase_table_name" {
  description = "Supabase table name for recordings"
  type        = string
  default     = "recordings"
}
