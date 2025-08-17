# Пользователь виртуалок

variable "ssh_public_key_path" {
  type    = string
  default = "~/ssh/id_rsa.pub"
}

variable "ssh_user" {
  type    = string
  default = "user"
}

# Характеристики вм

variable "web_cores" {
  type    = number
  default = 2
}
variable "web_memory" {
  type    = number
  default = 2048
}
variable "bastion_cores" {
  type    = number
  default = 2
}
variable "bastion_memory" {
  type    = number
  default = 2048
}

