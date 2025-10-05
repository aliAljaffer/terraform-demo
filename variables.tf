variable "subscription_id" {
  type        = string
  description = "Subscription ID that you want to provision resources to"
  sensitive   = true
}
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "admin_username" {
  type      = string
  sensitive = true
}
