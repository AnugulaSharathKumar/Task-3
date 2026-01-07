variable "project_id" {
  description = "GCP project id"
  type        = string
  default     = "project-3e800f45-77e7-454a-a2b"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-south1-a"
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "e2-medium"
}

variable "ssh_keys" {
  description = "SSH keys metadata (format: user:ssh-rsa ...)"
  type        = string
  default     = ""
}
