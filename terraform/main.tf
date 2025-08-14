provider "yandex" {

  folder_id = "b1ggikaja1av3posr20i"

}

# Бастион инстанс 

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts-oslogin"
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = false
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
    preemptible = false
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
    ssh-keys  = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
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

# Zabbix
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = false
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
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Zabbix

#Elasticsearch
resource "yandex_compute_instance" "elastic" {
  name        = "elastic"
  hostname    = "elastic"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = false
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-1.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elc-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
#Elasticsearch

#Kibana
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = false
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
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
#Kibana




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



# resource "yandex_compute_snapshot_schedule" "daily_snapshots" {
  
#   name        = "daily-snapshots"
#   description = "snapshoooots"
#   retention_period = "160h"

#   schedule_policy {
#     expression = "0 0 ? * *"
#   }
#    disk_ids = ["yandex_compute_instance.bastion.boot_disk","yandex_compute_instance.zabbix.boot_disk","yandex_compute_instance.elastic.boot_disk","yandex_compute_instance.zabbix.boot_disk","yandex_compute_instance.kibana.boot_disk"]
# }
