variable "region" {
  description = "AWS Region for every resource in the lab"
  type        = string
  default     = "us-east-1"
}

variable "lab_name" {
  description = "Unique lowercase name, used for the bucket, the table, the functions and the roles"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}[a-z0-9]$", var.lab_name))
    error_message = "Use 3-42 lowercase letters, digits and hyphens. The bucket name must be globally unique."
  }
}
