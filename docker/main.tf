/*

notes 

- commands:
    terraform init => to initialize
    terraform plan => to evaluate the configurations
    terraform apply => to deploy, and use '--auto-approve' to skip interactive approval
    terraform fmt => to format the .tf document, and use '-diff' to see the differences
    terraform show => to see the configurations in the tfstate. tip: forward the result to grep or jq
- functions:
    join
        join(separator, list)
        join(", ", ["foo", "bar", "baz"]) # result> foo, bar, baz
        https://www.terraform.io/language/functions/join
- tips:
    Remember: Everytime you add a new resource you need to do '$terraform init'
    Use auto indent and auto format in VSCode:
    https://linuxpip.org/auto-indent-vscode/ 

*/

# using docker provider

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

provider "docker" {}

/*
  random_string
  Use the random resource provider to gerate random string, numbers or other
  In the code below it's generating a single random string that can be used like => random_string.random.result
  https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
*/

resource "random_string" "random" {
  length  = 4
  special = false
  upper   = false
}

# pulls the image
resource "docker_image" "nodered" {
  name = "nodered/node-red:latest"
}

# create a container using join and random_string
resource "docker_container" "nodered" {
  image = docker_image.nodered.latest
  name  = join("-", ["nodered", random_string.random.result])
  ports {
    internal = 1880
    # external = 1880
  }
}

/*
  output
  Use output to export/expose a value after the deployment
  Examples:
    docker_container.nodered.name
    docker_container.nodered.ip_address
    docker_container.nodered.ports[0].external
  https://www.terraform.io/language/values/outputs
*/

# output the container name
output "container_name" {
  value = docker_container.nodered.name
}

# using join to output the ip + external port
output "container_url" {
  value       = join(":", [docker_container.nodered.ip_address, docker_container.nodered.ports[0].external])
  description = "Nodered container #1 URL"
}
