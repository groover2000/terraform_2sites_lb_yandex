# Группы доступности для виртуалок

# Группа для бастиона
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "Группа для бастион сервера"
  network_id  = yandex_vpc_network.loshadka.id
}

# Группа для сайтов
resource "yandex_vpc_security_group" "web-sg" {
  name        = "web-sg"
  description = "Группа для для сайтов"
  network_id  = yandex_vpc_network.loshadka.id
}

# Группа для zabbix
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix-sg"
  description = "Группа для zabbix"
  network_id  = yandex_vpc_network.loshadka.id
}

# Группа elastic
resource "yandex_vpc_security_group" "elc-sg" {
  name        = "elc-sg"
  description = "Группа для elc"
  network_id  = yandex_vpc_network.loshadka.id
}

# Группа kibana
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  description = "Группа для elc"
  network_id  = yandex_vpc_network.loshadka.id
}

# Группы доступности для виртуалок