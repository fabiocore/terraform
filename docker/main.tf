/*

notes 

- install terraform => https://learn.hashicorp.com/tutorials/terraform/install-cli

- commands:
    terraform init => to initialize
    terraform plan => to evaluate the configurations
    terraform apply => to deploy, and use '--auto-approve' to skip interactive approval
    terraform fmt => to format the .tf document, and use '-diff' to see the differences
    terraform show => to see the configurations in the tfstate. tip: forward the result to grep or jq
    terraform outputs => expose the configured outputs
    terraform state list => list the resources in the state, useful to get some values for output
    terraform taint <resource> => mark a resource to be replaced
    terraform untaint <resource> => unmark a resource to be replaced

- functions:
    join
        join(separator, list)
        join(", ", ["foo", "bar", "baz"]) # result> foo, bar, baz
        https://www.terraform.io/language/functions/join
        
- tips:
    Remember that everytime you add a new resource you need to do '$terraform init'
    Use auto indent and auto format in VSCode => https://linuxpip.org/auto-indent-vscode/ 

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
  working with variables
  https://www.terraform.io/language/values/variables
*/

# Defining a variable within the document
variable "ext_port" {
  type    = number
  default = 1880
  # optional validation below
  validation {
    condition     = var.ext_port == 1880
    error_message = "Error! The port number needs to be 1880."
  }
}

/*
  Getting an variable from current environment
  https://www.gitpod.io/docs/environment-variables
  Do the following for gitpod:
  $gp env TF_VAR_internal_port #define the variable
  $eval $(gp env -e) #update in your current terminal/session
  - when you define a environment variable, always include the prefix TF_VAR_
  - when getting the variable, remove the prefix like internal_port
*/

variable "internal_port" {}

output "internal_port" {
  value       = var.internal_port
  description = "defined in the envrionement as TF_VAR_internal_port"
}

# Getting the var from terraform.tfvars
variable "sensitive_text" {}

output "sensitive_text" {
  value = var.sensitive_text
}

/*
  using local-exec to create a volume to be used in docker
*/

resource "null_resource" "dockervol" {
  provisioner "local-exec" {
    command = "mkdir noderedvol/ || true && sudo chown -R 1000:1000 noderedvol"
  }
}

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
    # internal = 1880
    internal = var.internal_port
    external = var.ext_port
  }
  volumes {
    container_path = "/data"
    host_path      = "/workspace/terraform/docker/noderedvol"
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
output "nodered_container_name" {
  value       = docker_container.nodered.name
  description = "nodered container name"
}

# using join to output the ip + external port
output "nodered_url" {
  value       = join(":", [docker_container.nodered.ip_address, docker_container.nodered.ports[0].external])
  description = "nodered container #1 URL"
}

/*
  count
  meta-argument that can be used with modules, resource and "data" blocks
*/

# generate two random_string values
resource "random_string" "random_values" {
  count   = 2
  length  = 4
  special = false
  upper   = false
}

# pull nginx image
resource "docker_image" "nginx_image" {
  name = "nginx:latest"
}

# deploy two node containers using the count meta-argument and getting random generated strings
resource "docker_container" "nginx_container" {
  count = 2
  name  = join("-", ["nginx", random_string.random_values[count.index].result])
  image = docker_image.nginx_image.latest
  ports {
    internal = 8080
    # external = 8080
  }
}

# using output with the special * to see the values generated randomly
output "nginx_container_name" {
  value       = docker_container.nginx_container[*].name
  description = "nginx container at index 0"
}

# using output with for expression to generate a list of ip:port generated randomly
output "nginx_container_ip_port" {
  value       = [for i in docker_container.nginx_container[*] : join(":", ["http://"], [i.ip_address], i.ports[*]["external"])]
  description = "the ip and port for each container"
}
