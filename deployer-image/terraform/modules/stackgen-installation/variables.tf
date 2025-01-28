variable "suffix" {
  description = "The suffix to be used for the resources"
  type        = string
}

variable "namespace" {
  description = "The namespace in AKS cluster where the stackgen will be deployed"
  type        = string
  default     = "stackgen"
}

variable "stackgen_authentication" {
  description = "The auth configuration for the appcd"
  type = object({
    type   = string
    config = any
  })
  default = {
    type   = "none"
    config = {}
  }
}

variable "domain" {
  description = "The domain for the appcd without the protocol"
  type        = string
}

variable "STACKGEN_PAT" {
  description = "The PAT for the stackgen repository. (This is a sensitive entry)"
  type        = string
  sensitive   = true
}

variable "enable_ops" {
  description = "Enable the Ops portal"
  default     = false
}


variable "stackgen_version" {
  description = "The version of the appcd to deploy"
  type        = string
  default     = "0.5.1"
}

variable "enable_feature" {
  description = "stackgen features to enable"
  type = object({
    llm = optional(bool, false)
  })
  default = {
    llm = false
  }
}

variable "admin_emails" {
  description = "The email ids of the admin users"
  type        = list(string)
  default     = []
}
variable "scm_configuration" {
  description = "The SCM configuration for the appcd"
  type = object({
    scm_type = string # could be none, github, gitlab, azuredev
    github_config = optional(object({
      client_id     = string
      client_secret = string
      auth_url      = optional(string, "https://github.com/login/oauth/authorize")
      token_url     = optional(string, "https://github.com/login/oauth/access_token")
    }))
    gitlab_config = optional(object({
      client_id     = string
      client_secret = string,
      auth_url      = optional(string, "https://gitlab.com/oauth/authorize")
      token_url     = optional(string, "https://gitlab.com/oauth/token")
    }))
    azuredev_config = optional(object({
      client_id     = string
      client_secret = string
      auth_url      = optional(string, "https://app.vssps.visualstudio.com/oauth2/authorize")
      token_url     = optional(string, "https://app.vssps.visualstudio.com/oauth2/token")
    }))
  })
  default = {
    scm_type = "none"
    github_config = {
      client_id     = ""
      client_secret = ""
    }
    gitlab_config = {
      client_id     = ""
      client_secret = ""
    }
    azuredev_config = {
      client_id     = ""
      client_secret = ""
    }
  }
}
variable "additional_secrets" {
  description = "Additional secrets that are to be injected to the appcd installation. This can be handy if you are configuring auth and SCM configurations"
  type        = list(string)
  default     = []
}

variable "storage" {
  description = "The name of the volume to be used for the appcd"
  type = object({
    volume = string
    class  = string
  })
  default = {
    class  = ""
    volume = ""
  }
}
variable "global_static_ip_name" {
  type        = string  
}
variable "pre_shared_cert_name" {
  type        = string
}
