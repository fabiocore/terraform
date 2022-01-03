terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

provider "docker" {}

variable "int_port" {
  default = 3000
  validation {
    condition     = var.int_port == 3000
    error_message = "The frana port must be set to 3000."
  }
}

variable "ext_port" {}

resource "docker_image" "grafana_image" {
  name = "grafana/grafana"
}

resource "docker_container" "grafana_container" {
  count = 2
  image = docker_image.grafana_image.latest
  name  = "grafana-${count.index}"
  ports {
    internal = var.int_port
    external = var.ext_port[count.index]
  }
}

output "public_ip" {
  value = [for x in docker_container.grafana_container : "${x.name} - ${x.ip_address}:${x.ports[0].external}"]
}
