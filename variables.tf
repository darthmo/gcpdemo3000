variable "region" {
  type        = string
  description = "region del proyecto"
  default     = "us-central1"
}

variable "project_id" {
  type        = string
  description = "El proyecto donde se van a crear los recursos"
}

variable "zone" {
  type = string
  description = "La zona de la region donde se crearan los recursos"
}

variable "tf_service_account" {
  type = string
  description = "La service account que se usa para crear recursos"
}
