terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "centos-1" {
  name   = "centos-1.0"
  pool   = "default"
  source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  format = "qcow2"
}


resource "libvirt_domain" "domain-centos7" {
  name   = "centos7"
  memory = 1024
  vcpu   = 1

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = "true"
  }
}

output "ips" {
  # show IP, run 'terraform refresh' if not populated
  value = libvirt_domain.domain-centos7.network_interface.0.addresses
}

