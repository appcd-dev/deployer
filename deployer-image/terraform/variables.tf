variable "suffix" {
  type        = string
  description = "Suffix to all names"
  default     = "marketplace"
}

variable "domain" {
  description = "The domain for the appcd without the protocol"
  type        = string
}

variable "STACKGEN_PAT" {
  description = "The GitHub Personal Access Token for the stackgen repository. (This is a sensitive entry)"
  type        = string
  sensitive   = true
}

variable "labels" {
  type        = map(string)
  description = "labels to apply to all resources"
  default     = {}
}

variable "global_static_ip_name" {
  type = string
}
variable "pre_shared_cert_name" {
  type = string
}

variable "nginx_config" {
  type = object({
    client_max_body_size = string
  })
  default = {
    client_max_body_size = "10M"
  }
  description = "NGINX configuration settings"
}

variable "enable_feature" {
  description = "stackgen features to enable"
  type = object({
    exporter          = optional(bool, true)
    llm               = optional(bool, false)
    vault             = optional(bool, true)
    enable_group_sync = optional(bool, false)
    artifacts_support = optional(bool, false)
    need_user_vetting = optional(bool, false)
    editableIac       = optional(bool, false)
    moduleEditor      = optional(bool, false)
    log_analysis      = optional(bool, false)
    integrations      = optional(bool, false)
    backstage_adapter = optional(bool, false)
  })
  default = {
    exporter          = true
    vault             = true
    llm               = false
    enable_group_sync = false
    artifacts_support = false
    need_user_vetting = false
    editableIac       = true
    moduleEditor      = true
    log_analysis      = false
    integrations      = true
    backstage_adapter = false
  }
}
