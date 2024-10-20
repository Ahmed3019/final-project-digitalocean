# Declare a variable for the DigitalOcean token
variable "digitalocean_token" {
  description = "DigitalOcean API Token"
  type        = string
}

# Use the DigitalOcean provider
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"  # Specify a version or use a range
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

# Create a VPC in DigitalOcean with a non-overlapping IP range
resource "digitalocean_vpc" "my_vpc" {
  name      = "my-vpc-new"  # Ensure this name is unique
  region    = "fra1"  # Frankfurt region
  ip_range  = "10.1.0.0/16"  # Updated IP range
}

# Create a droplet (DigitalOcean equivalent of an EC2 instance)
resource "digitalocean_droplet" "my_instance" {
  image     = "ubuntu-20-04-x64"  # Choose an Ubuntu image
  name      = "my-droplet"
  region    = "fra1"  # Frankfurt region
  size      = "s-2vcpu-8gb-amd"  # Set to a valid droplet size
  vpc_uuid  = digitalocean_vpc.my_vpc.id  # Reference the created VPC

  ssh_keys  = ["43804899"]  # Use the ID of your existing SSH key

  # Add dependency to ensure the VPC is created before the droplet
  depends_on = [digitalocean_vpc.my_vpc]
}

# Create a firewall for the droplet to allow SSH (port 22), HTTP (port 80), and custom port (8080)
resource "digitalocean_firewall" "my_firewall" {
  name        = "my-firewall"
  droplet_ids = [digitalocean_droplet.my_instance.id]

  # Allow SSH from anywhere
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  # Allow HTTP from anywhere
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  # Allow custom port 8080 from anywhere
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
    source_addresses = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol             = "icmp"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# Output the public IP of the droplet
output "instance_ip" {
  value = digitalocean_droplet.my_instance.ipv4_address
}
