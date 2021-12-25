/*

Notes:

- Remember: Everytime you add a new resource you need to do '$terraform init'
- You can run '$terraform fmt' to format the document or
  '$terraform fmt -diff' to format and see what is changed.
  Alternativelly you can use auto indent and auto format in VSCode:
  https://linuxpip.org/auto-indent-vscode/ 
- Join functions can be use for concatenating elements
  join(separator, list)
  join(", ", ["foo", "bar", "baz"]) # result> foo, bar, baz

*/

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

provider "docker" {}

# Use the random resource provider to gerate random string, numbers or other
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "random" {
  length  = 4
  special = false
  upper   = false
}

resource "random_string" "random2" {
  length  = 4
  special = false
  upper   = false
}

# Pulls the image
resource "docker_image" "nodered" {
  name = "nodered/node-red:latest"
}

# Create a container
resource "docker_container" "nodered" {
  image = docker_image.nodered.latest
  name  = join("-", ["nodered", random_string.random.result])
  ports {
    internal = 1880
    # external = 1880
  }
}

resource "docker_container" "nodered2" {
  image = docker_image.nodered.latest
  name  = join("-", ["nodered", random_string.random2.result])
  ports {
    internal = 1880
    # external = 1880
  }
}

# Use output value to expose/explort information after deploying a resource
# https://www.terraform.io/language/values/outputs
output "container_name" {
  value = docker_container.nodered.name
}

output "container_ip_addr" {
  value = docker_container.nodered.ip_address
}

output "container_ext_port" {
  value = docker_container.nodered.ports[0].external
}

output "container_url" {
  value       = join(":", [docker_container.nodered.ip_address, docker_container.nodered.ports[0].external])
  description = "Nodered container #1 URL"
}

output "container2_url" {
  value       = join(":", [docker_container.nodered.ip_address, docker_container.nodered2.ports[0].external])
  description = "Nodered container #2 URL"
}