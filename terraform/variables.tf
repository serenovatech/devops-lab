variable "environment" {
  description = "Name used in the network and container names"
  type        = string
  default     = "dev"
}

variable "image" {
  description = "Poultry image to run. It must already exist on the VM (built in lab 3)."
  type        = string
  default     = "poultry-lab:1.0"
}

variable "replicas" {
  description = "How many copies of the app to run"
  type        = number
  default     = 2

  validation {
    condition     = var.replicas >= 1 && var.replicas <= 3
    error_message = "Use between 1 and 3 replicas: this VM has limited memory."
  }
}

variable "base_port" {
  description = "VM port of the first copy. Each further copy uses the next port."
  type        = number
  default     = 4000
}

variable "db_password" {
  description = "Password for this lab's own database"
  type        = string
  sensitive   = true
  default     = "terraform-lab-only"
}
