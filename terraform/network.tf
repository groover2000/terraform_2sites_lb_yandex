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
## Лишняя, а может пока и нет
# resource "yandex_vpc_subnet" "public-2" {
#   name           = "public-2"
#   zone           = "ru-central1-b"
#   network_id     = yandex_vpc_network.loshadka.id
#   v4_cidr_blocks = ["192.168.2.0/24"]
# }

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

  ## Если завтыкал, не трогой роутер, между собой общаются автоматом(даже из разных зон в одной сети), если не общаются, косяк в группах или конфига()

}

# Сеть для виртуалок