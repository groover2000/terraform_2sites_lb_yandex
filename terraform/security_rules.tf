# Группы 
# bastion-sg --------Бастион сервер 
# web-sg --------Сайты
# zabbix-sg ------zabbix
# elc-sg -----Эластик
# kibana-sg ------ kibana



#------------------------------------
### БАСТИОН
# Разрешает входящий ssh для бастиона
resource "yandex_vpc_security_group_rule" "ssh-rule-inbound" {

  security_group_binding = yandex_vpc_security_group.bastion-sg.id
  direction              = "ingress"
  description            = "Разрешает входящий ssh"
  protocol               = "ANY"
  port                   = 22
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "ssh-rule-outbound" {

  security_group_binding = yandex_vpc_security_group.bastion-sg.id
  direction              = "egress"
  description            = "Разрешает исходящий ssh"
  protocol               = "ANY"
  port                   = 22
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
# Разрешает входящий ssh для бастиона
### БАСТИОН
#------------------------------------


#-------------------------------------
# САЙТЫ
# Разрешает ssh для сайтов от бастиона
resource "yandex_vpc_security_group_rule" "ssh-rule-web-inbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "ingress"
  description            = "Разрешает входящий ssh для web сайтов только с бастион сервера"
  protocol               = "TCP"
  port                   = 22
  v4_cidr_blocks         = ["192.168.1.0/24", "192.168.2.0/24"]

}
resource "yandex_vpc_security_group_rule" "ssh-rule-web-outbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "egress"
  description            = "Разрешает исходящий ssh для web сайтов только с бастион сервера"
  protocol               = "TCP"
  port                   = 22
  v4_cidr_blocks         = ["192.168.1.0/24", "192.168.2.0/24"]

}

# Разрешает ssh для сайтов от бастиона

# Разрешает http трафик для сайтов
resource "yandex_vpc_security_group_rule" "web-http-inbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "ingress"
  description            = "Разрешает входящий http трафик"
  protocol               = "TCP"
  port                   = 80
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "web-http-outbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "egress"
  description            = "Разрешает исходящий http трафик"
  protocol               = "TCP"
  port                   = 80
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
# Разрешает http трафик для сайтов

# Для zabbix
resource "yandex_vpc_security_group_rule" "web-zabbix-inbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "ingress"
  description            = "Входящий zabbix agent"
  protocol               = "ANY"
  port                   = 10050
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "web-zabbix-outbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "egress"
  description            = "Входящий zabbix agent"
  protocol               = "ANY"
  port                   = 10050
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "web-zabbix-trapper-inbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "ingress"
  description            = "Входящий zabbix trapper"
  protocol               = "ANY"
  port                   = 10051
  v4_cidr_blocks         = ["0.0.0.0/0"]

}

resource "yandex_vpc_security_group_rule" "wevb-zabbix-trapper-outbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "egress"
  description            = "Исходящий zabbix trapper"
  protocol               = "ANY"
  port                   = 10051
  v4_cidr_blocks         = ["0.0.0.0/0"]

}

# Для zabbix

# САЙТЫ
#---------------------------------

#---------------------------------
# Zabbix-agent
resource "yandex_vpc_security_group_rule" "zabbix-agent-all" {

  security_group_binding = yandex_vpc_security_group.zabbix-sg.id
  direction              = "ingress"
  description            = "Входящий zabbix agent"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "zabbix-agent-all2" {

  security_group_binding = yandex_vpc_security_group.zabbix-sg.id
  direction              = "egress"
  description            = "Входящий zabbix agent"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "zabbix-agent-inbound" {

  security_group_binding = yandex_vpc_security_group.zabbix-sg.id
  direction              = "ingress"
  description            = "Входящий zabbix agent"
  protocol               = "ANY"
  port                   = 10050
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "zabbix-agent-outbound" {

  security_group_binding = yandex_vpc_security_group.zabbix-sg.id
  direction              = "egress"
  description            = "Исходящий zabbix agent"
  protocol               = "ANY"
  port                   = 10050
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
#---------------------------------
# Zabbix-agent


# Zabbix-trapper
resource "yandex_vpc_security_group_rule" "zabbix-trapper-inbound" {

  security_group_binding = yandex_vpc_security_group.zabbix-sg.id
  direction              = "ingress"
  description            = "Входящий zabbix trapper"
  protocol               = "TCP"
  port                   = 10051
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "zabbix-trapper-outbound" {

  security_group_binding = yandex_vpc_security_group.zabbix-sg.id
  direction              = "egress"
  description            = "Исходящий zabbix trapper"
  protocol               = "TCP"
  port                   = 10051
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
#---------------------------------
# Zabbix-trapper




#KIBANA

resource "yandex_vpc_security_group_rule" "kibana-outbound" {

  security_group_binding = yandex_vpc_security_group.kibana-sg.id
  direction              = "egress"
  description            = "ALL egress"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "kibana-inbound" {

  security_group_binding = yandex_vpc_security_group.kibana-sg.id
  direction              = "ingress"
  description            = "ALL ingress"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  v4_cidr_blocks         = ["0.0.0.0/0"]

}

#KIBANA


# ELASTIC
resource "yandex_vpc_security_group_rule" "elastic-outbound" {

  security_group_binding = yandex_vpc_security_group.elc-sg.id
  direction              = "egress"
  description            = "ALL egress"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
resource "yandex_vpc_security_group_rule" "elastic-intbound" {

  security_group_binding = yandex_vpc_security_group.elc-sg.id
  direction              = "ingress"
  description            = "ALL ingress"
  protocol               = "ANY"
  from_port              = 0
  to_port                = 65535
  v4_cidr_blocks         = ["0.0.0.0/0"]

}
# ELASTIC