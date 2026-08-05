variable "name_prefix" {
  description = "Base name used to derive resource names."
  type        = string
  default     = "koekagami"
}

variable "location" {
  description = "Azure region for the resources."
  type        = string
  default     = "eastus2"
}

variable "openai_location" {
  description = "Azure region for the Azure OpenAI account (model availability varies by region)."
  type        = string
  default     = "eastus2"
}

variable "openai_deployment_name" {
  description = "Name of the Azure OpenAI model deployment."
  type        = string
  default     = "gpt-4o"
}

variable "openai_model_name" {
  description = "Azure OpenAI model name."
  type        = string
  default     = "gpt-4o"
}

variable "openai_model_version" {
  description = "Azure OpenAI model version."
  type        = string
  default     = "2024-08-06"
}

variable "backend_image" {
  description = "Container image for the backend app."
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "frontend_image" {
  description = "Container image for the frontend app."
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    project = "koe-kagami"
  }
}
