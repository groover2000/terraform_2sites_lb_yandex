
provider "yandex" {

}


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

# Разрешает входящий ssh для бастиона
resource "yandex_vpc_security_group_rule" "ssh-rule-inbound" {

  security_group_binding = yandex_vpc_security_group.bastion-sg.id
  direction              = "ingress"
  description            = "Разрешает входящий ssh"
  protocol               = "ANY"
  from_port = 0
  to_port = 10000
  v4_cidr_blocks         = ["0.0.0.0/0"]

}

resource "yandex_vpc_security_group_rule" "ssh-rule-outbound" {

  security_group_binding = yandex_vpc_security_group.bastion-sg.id
  direction              = "egress"
  description            = "Разрешает входящий ssh"
  protocol               = "ANY"
  from_port = 0
  to_port = 10000
  v4_cidr_blocks         = ["0.0.0.0/0"]

}

# Разрешает ssh для сайтов от бастиона
resource "yandex_vpc_security_group_rule" "ssh-rule-web-inbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "ingress"
  description            = "Разрешает входящий ssh для web сайтов только с бастион сервера"
  protocol               = "TCP"
  port                   = 22
  v4_cidr_blocks         = ["192.168.1.0/24","192.168.2.0/24"]

}
resource "yandex_vpc_security_group_rule" "ssh-rule-web-outbound" {

  security_group_binding = yandex_vpc_security_group.web-sg.id
  direction              = "ingress"
  description            = "Разрешает входящий ssh для web сайтов только с бастион сервера"
  protocol               = "TCP"
  port                   = 22
  v4_cidr_blocks         = ["192.168.1.0/24","192.168.2.0/24"]

}
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
  description            = "Разрешает входящий http трафик"
  protocol               = "TCP"
  port                   = 80
  v4_cidr_blocks         = ["0.0.0.0/0"]

}

# Группы доступности для виртуалок


# Сеть для виртуалок

resource "yandex_vpc_network" "loshadka" {
  name        = "loshadka"
  description = "Локалка для сайтов"
}

resource "yandex_vpc_subnet" "public-1" {
  name           = "public-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.loshadka.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

resource "yandex_vpc_subnet" "public-2" {
  name           = "public-2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.loshadka.id
  v4_cidr_blocks = ["192.168.2.0/24"]
}

resource "yandex_vpc_subnet" "private-1" {
  name           = "private-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.loshadka.id
  v4_cidr_blocks = ["192.168.10.0/24"]
  route_table_id = yandex_vpc_route_table.private-rt.id
}

resource "yandex_vpc_subnet" "private-2" {
  name           = "private-2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.loshadka.id
  v4_cidr_blocks = ["192.168.11.0/24"]
  route_table_id = yandex_vpc_route_table.private-rt.id
}

# NAT для выхода наружу, чтобы виртуалки могли качать пакеты
resource "yandex_vpc_gateway" "nat" {
  name = "nat-gw"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private-rt" {
  network_id = yandex_vpc_network.loshadka.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}



# Сеть для виртуалок


# Бастион инстанс 

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts-oslogin"
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-1.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
# Бастион инстанс

#Web инстанс
resource "yandex_compute_instance" "site" {
  count       = 2
  name        = "site-${count.index + 1}"
  hostname    = "site-${count.index + 1}"
  platform_id = "standard-v1"
  zone        = count.index == 0 ? "ru-central1-a" : "ru-central1-b"


  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = count.index == 0 ? yandex_vpc_subnet.private-1.id : yandex_vpc_subnet.private-2.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    user-data = <<-EOF
                #cloud-config
                package_update: true
                package_upgrade: true
                packages:
                  - nginx
                runcmd:
                  - echo "Hello World" > /var/www/html/index.html
                  - systemctl enable nginx
                  - systemctl restart nginx
                EOF
  }
}

#Web инстанс


# Балансировщик

resource "yandex_alb_target_group" "web-tg" {
  name = "web-tg"

  target {
    subnet_id  = yandex_vpc_subnet.private-1.id
    ip_address = yandex_compute_instance.site[0].network_interface[0].ip_address
  }
  target {
    subnet_id  = yandex_vpc_subnet.private-2.id
    ip_address = yandex_compute_instance.site[1].network_interface[0].ip_address
  }
}

resource "yandex_alb_backend_group" "backend" {

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web-tg.id]

    healthcheck {
      interval = "3s"
      timeout  = "1s"
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "router" {
  name = "site-router"

}

resource "yandex_alb_virtual_host" "vh" {
  name           = "site-vh"
  http_router_id = yandex_alb_http_router.router.id

  route {
    name = "route"
    http_route {

      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "balancer" {
  name       = "balancer"
  network_id = yandex_vpc_network.loshadka.id
  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public-1.id
    }
  }

  listener {
    name = "http-listener"
    http {
      handler {
        http_router_id = yandex_alb_http_router.router.id
      }
    }
    endpoint {
      address {
        external_ipv4_address {

        }
      }
      ports = [80]

    }
  }
}

# Балансировщик



# Оутпутсы
# Outputs we need for Ansible
output "bastion_public_ip" {
  value = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "web_private_ips" {
  value = [
    for inst in yandex_compute_instance.site : inst.network_interface[0].ip_address
  ]
}

output "alb_ip" {
  value       = yandex_alb_load_balancer.balancer.listener[0].endpoint[0].address[0].external_ipv4_address
  description = "External IP of ALB"
}
