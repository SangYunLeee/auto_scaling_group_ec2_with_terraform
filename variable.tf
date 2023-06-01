variable "email" {
  description = "SNS 을 통해서 오토스케일링 정보를 받을 email"
  type        = string
  default     = "someone@gmail.com"
}

variable "pair_key" {
  description = "PAIR KEY FOR EC2"
  type        = string
  default     = "key"
}
