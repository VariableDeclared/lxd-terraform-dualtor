terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
      version = "1.9.1"
    }
  }
}


provider "lxd" {
}



resource "lxd_network" "lxd_ToR_Net" {
  name = "lxd_ToR_Net_19"

  config = {
    "ipv4.address" = "10.150.19.1/24"
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
    "ipv6.nat"     = "false"
  }
}
resource "lxd_network" "lxd_ToR_Net2" {
  name = "lxd_ToR_Net_18"

  config = {
    "ipv4.address" = "10.150.18.1/24"
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
    "ipv6.nat"     = "false"
  }
}

resource "lxd_profile" "dual_tor_profile" {
  name = "dual_tor_profile"
  config = {
      "linux.kernel_modules" =  "ip_vs,ip_vs_rr,ip_vs_wrr,ip_vs_sh,ip_tables,ip6_tables,netlink_diag,nf_nat,overlay,br_netfilter"  
      "raw.lxc" = "${file("${path.module}/raw.lxc")}"
  }
  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = "lxdbr0"
    }
  }
  device {
    name = "eth1"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = "${lxd_network.lxd_ToR_Net.name}"
    }
  }
  device {
    name = "eth2"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = "${lxd_network.lxd_ToR_Net2.name}"
    }
  }
  device {
    type = "disk"
    name = "aadisable"

    properties = {
      source = "/sys/module/nf_conntrack/parameters/hashsize"
      path = "/sys/module/nf_conntrack/parameters/hashsize"
    }
  }
  device {
    type = "unix-char"
    name = "aadisable2"

    properties = {
      source = "/dev/kmsg"
      path = "/dev/kmsg"
    }
  }
  device {
    type = "disk"
    name = "aadisable3"

    properties = {
      source = "/dev/kmsg"
      path = "/dev/kmsg"
    }
  }
  device {
    type = "disk"
    name = "aadisable4"

    properties = {
      source = "/proc/sys/net/netfilter/nf_conntrack_max"
      path = "/proc/sys/net/netfilter/nf_conntrack_max"
    }
  }
  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }
}
# data "local_file" "cloud_init" {
#     filename = "${path.module}/cloud-init.yaml"
# }
# data "local_file" "raw_lxd" {
#     filename = "${path.module}/raw.lxc"
# }
resource "lxd_container" "ToR1" {
  name      = "ToR1"
  image     = "images:ubuntu/22.04"
  ephemeral = false
  profiles  = ["${lxd_profile.dual_tor_profile.name}"]

  config = {
    "boot.autostart" = true
    "cloud-init.user-data" = "${file("${path.module}/cloud-init-tor1.yaml")}"
  }

  limits = {
    cpu = 2
  }
}

resource "lxd_container" "ToR2" {
  name      = "ToR2"
  image     = "images:ubuntu/22.04"
  ephemeral = false
  profiles  = ["${lxd_profile.dual_tor_profile.name}"]

  config = {
    "boot.autostart" = true
    "cloud-init.user-data" = "${file("${path.module}/cloud-init-tor2.yaml")}"

  }

  limits = {
    cpu = 2
  }
}