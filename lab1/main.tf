terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "grafana_image" {
  name = "grafana/grafana"
}

resource "docker_container" "grafana_container" {
  image = docker_image.grafana_image.latest
  name  = "grafana"
  ports {
    internal = 3000
    external = 3000
  }
}