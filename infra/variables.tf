variable "location" {
  description = "Região permitida pela política da assinatura"
  type        = string
  default     = "northcentralus"
}

variable "prefixo" {
  description = "Prefixo dos nomes dos recursos"
  type        = string
  default     = "nuvelo"
}

variable "location_sql" {
  description = "Região do SQL Server (northcentralus bloqueia SQL na oferta de estudante)"
  type        = string
  default     = "francecentral"
}
