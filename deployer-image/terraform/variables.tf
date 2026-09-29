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

variable "component_versions" {
  description = "Image versions pinned by the deployment and returned from /version.json."
  type = object({
    appcd       = optional(string, "v2025.1.3")
    iacgen      = optional(string, "v0.22.0")
    ui          = optional(string, "v0.10.11")
    exporter    = optional(string, "v0.4.0")
    llm_gateway = optional(string, "v0.2.3")
    vault       = optional(string, "v0.1.0")
    guild       = optional(string, "v0.2.28-hotfix.4")
    gateway     = optional(string, "v0.2.28-hotfix.2")
    guild_ui    = optional(string, "v0.2.28-hotfix.2")
  })
  default = {}
}
variable "guild_enabled" {
  description = "Enable nginx routes for Guild services installed separately in this namespace."
  type        = bool
  default     = false
}

variable "global_static_ip_name" {
  type = string
}
variable "pre_shared_cert_name" {
  type = string
}
