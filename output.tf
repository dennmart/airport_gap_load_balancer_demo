output "web_server_public_ipv4_addresses" {
  value = hcloud_server.web_server[*].ipv4_address
}

output "worker_public_ipv4_addresses" {
  value = hcloud_server.worker.ipv4_address
}

output "primary_db_server_public_ipv4_addresses" {
  value = hcloud_server.primary_db_server.ipv4_address
}

output "redis_server_public_ipv4_addresses" {
  value = hcloud_server.redis_server.ipv4_address
}

output "primary_db_server_private_ipv4_address" {
  value = hcloud_server.primary_db_server.network[*].ip
}

output "redis_server_private_ipv4_address" {
  value = hcloud_server.redis_server.network[*].ip
}
