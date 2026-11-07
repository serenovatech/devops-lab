# Docker stands in for a cloud here: the same plan and apply steps work for AWS or Proxmox,
# without any cost or account. Everything here is separate from your real staging app.
resource "docker_network" "lab" {
  name = "lab-tf-${var.environment}"
}

resource "docker_image" "mysql" {
  name         = "mysql:8.4"
  keep_locally = true
}

resource "docker_image" "app" {
  name         = var.image
  keep_locally = true
}

resource "docker_volume" "mysql" {
  name = "lab-tf-${var.environment}-mysql"
}

resource "docker_container" "mysql" {
  name    = "lab-tf-${var.environment}-mysql"
  image   = docker_image.mysql.image_id
  restart = "unless-stopped"
  memory  = 768
  # Docker sets this to twice the memory limit anyway. Without it here, every plan shows a change.
  memory_swap = 1536
  command     = ["--innodb-buffer-pool-size=128M"]

  env = [
    "MYSQL_ROOT_PASSWORD=${var.db_password}",
    "MYSQL_DATABASE=poultry",
  ]

  volumes {
    volume_name    = docker_volume.mysql.name
    container_path = "/var/lib/mysql"
  }

  networks_advanced {
    name = docker_network.lab.name
  }
}

# The app exits if the database isn't ready yet, and Docker restarts it until it connects.
resource "docker_container" "app" {
  count = var.replicas

  name    = "lab-tf-${var.environment}-app-${count.index}"
  image   = docker_image.app.image_id
  restart = "unless-stopped"
  memory  = 384
  # Docker sets this to twice the memory limit anyway. Without it here, every plan shows a change.
  memory_swap = 768

  env = [
    "APP_ENV=staging",
    "DEMO_ENABLED=false",
    "DB_HOST=${docker_container.mysql.name}",
    "DB_USER=root",
    "DB_PASSWORD=${var.db_password}",
    "DB_NAME=poultry",
  ]

  ports {
    internal = 3000
    external = var.base_port + count.index
  }

  networks_advanced {
    name = docker_network.lab.name
  }
}
