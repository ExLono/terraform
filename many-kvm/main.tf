terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    #ignition = {
    #  source = "terraform-providers/ignition"
    #}
  }
}

# -[Provider]--------------------------------------------------------------
provider "libvirt" {
  uri = "qemu:///system"
}

# -[Variables]-------------------------------------------------------------
variable "hosts" {
  default = 1
}

variable "hostname_format" {
  type    = string
  default = "coreos%02d"
}

# variable "libvirt_provider" {
#   type = string
# }

# -[Resources]-------------------------------------------------------------
resource "libvirt_volume" "coreos-disk" {
  name  = "${format(var.hostname_format, count.index + 1)}.qcow2"
  count = var.hosts
  #base_volume_name = "coreos_production_qemu"
  pool   = "default"
  format = "qcow2"
  source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
}

#ignition directly from file
#resource "libvirt_ignition" "ignition" {
#  name    = "example.ign"
#  count   = var.hosts
#  content = "/home/den/git_projects/github/linux/fedora-coreos/create_vm_by_bash_command/example.ign"
#}

# Create the virtual machines
resource "libvirt_domain" "coreos-machine" {
  count  = var.hosts
  name   = format(var.hostname_format, count.index + 1)
  vcpu   = "1" #needed for minikube
  memory = "1024"
  connection {
    type        = "ssh"
    private_key = file("~/.ssh/id_rsa")

    user    = "root"
    timeout = "1m"
    host    = "127.0.0.1"
  }
  ## Use qemu-agent in conjunction with the container
  #qemu_agent = true
  #coreos_ignition = element(libvirt_ignition.ignition.*.id, count.index)

  disk {
    volume_id = element(libvirt_volume.coreos-disk.*.id, count.index)
  }

  graphics {
    ## Bug in linux up to 4.14-rc2
    ## https://bugzilla.redhat.com/show_bug.cgi?id=1432684
    ## No Spice/VNC available if more than one machine is generated at a time
    ## Comment the address line, uncomment the none line and the console block below
    #listen_type = "none"
    listen_type = "127.0.0.1"
  }

  ## Makes the tty0 available via `virsh console`
  #console {
  #  type = "pty"
  #  target_port = "0"
  #}

  network_interface {
    network_name = "default"

    # Requires qemu-agent container if network is not native to libvirt
    wait_for_lease = true
  }
  ## mounts filesystem local to the kvm host. used to patch in the
  ## qemu-guest-agent as docker container
  #filesystem {
  #  source = "/srv/images/"
  #  target = "qemu_docker_images"
  #  readonly = true
  #}


}

# -[Output]-------------------------------------------------------------
output "ipv4" {
  value = libvirt_domain.coreos-machine.*.network_interface.0.addresses
}
