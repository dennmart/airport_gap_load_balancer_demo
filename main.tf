terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.47.0"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_cloud_api_token
}

data "hcloud_ssh_key" "ssh_key" {
  name = "Airport Gap Demo"
}

resource "hcloud_firewall" "web_server" {
  name = "Web Server"

  rule {
    description = "Allow HTTP traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "Allow HTTPS traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall" "ssh" {
  name = "SSH"

  rule {
    description = "Allow SSH traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall" "postgres" {
  name = "Postgres"

  rule {
    description = "Allow PostgreSQL traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "5432"
    source_ips  = flatten([for server in hcloud_server.web_server : [for network in tolist(server.network) : network.ip]])
  }
}

resource "hcloud_firewall" "redis" {
  name = "Redis"

  rule {
    description = "Allow Redis traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "6379"
    source_ips  = hcloud_server.worker.network[*].ip
  }
}

resource "hcloud_network" "private_network" {
  name     = "Airport Gap Private Network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private_network.id
  network_zone = "us-west"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_server" "web_server" {
  count       = 3
  name        = "airportgap-web-${count.index + 1}"
  server_type = "cpx11"
  location    = "hil"
  image       = "ubuntu-22.04"
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id]
  firewall_ids = [
    hcloud_firewall.web_server.id,
    hcloud_firewall.ssh.id
  ]

  network {
    network_id = hcloud_network.private_network.id
    alias_ips  = []
  }

  labels = {
    server = "airportgap-web"
  }

  depends_on = [
    hcloud_network_subnet.private_network_subnet
  ]
}

resource "hcloud_server" "worker" {
  name        = "airportgap-worker"
  server_type = "cpx11"
  location    = "hil"
  image       = "ubuntu-22.04"
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id]

  network {
    network_id = hcloud_network.private_network.id
    alias_ips  = []
  }

  labels = {
    server = "airportgap-worker"
  }

  depends_on = [
    hcloud_network_subnet.private_network_subnet
  ]
}

resource "hcloud_server" "primary_db_server" {
  name        = "airportgap-db-primary"
  server_type = "cpx11"
  location    = "hil"
  image       = "ubuntu-22.04"
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id]
  firewall_ids = [
    hcloud_firewall.postgres.id,
    hcloud_firewall.ssh.id
  ]

  labels = {
    server = "airportgap-db"
  }

  network {
    network_id = hcloud_network.private_network.id
    alias_ips  = []
  }

  depends_on = [
    hcloud_network_subnet.private_network_subnet
  ]
}
resource "hcloud_server" "redis_server" {
  name        = "airportgap-redis"
  server_type = "cpx11"
  location    = "hil"
  image       = "ubuntu-22.04"
  ssh_keys    = [data.hcloud_ssh_key.ssh_key.id]
  firewall_ids = [
    hcloud_firewall.redis.id,
    hcloud_firewall.ssh.id
  ]

  network {
    network_id = hcloud_network.private_network.id
    alias_ips  = []
  }

  labels = {
    server = "airportgap-redis"
  }

  depends_on = [
    hcloud_network_subnet.private_network_subnet
  ]
}

resource "hcloud_load_balancer" "load_balancer" {
  name               = "airportgap-load-balancer"
  load_balancer_type = "lb11"
  location           = "hil"
}

resource "hcloud_load_balancer_target" "load_balancer_web" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  type             = "label_selector"
  label_selector   = "server=airportgap-web"
}

resource "hcloud_managed_certificate" "managed_cert" {
  name         = "Airport Gap Load Balancer"
  domain_names = ["balancer.airportgap.com"]
}

resource "hcloud_load_balancer_service" "load_balancer_service" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "https"

  http {
    redirect_http = true
    certificates  = [hcloud_managed_certificate.managed_cert.id]
  }

  health_check {
    protocol = "http"
    port     = 80
    interval = 10
    timeout  = 5

    http {
      path         = "/up"
      status_codes = ["200"]
    }
  }
}
