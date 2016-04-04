# These variables are received through ENV-variables created 
# by terraform-openrc.sh, hence, run that first

variable "password" {}
variable "user_name" {}
variable "tenant_name" {}

# A little bit hackish, but for demo purposes; why not
variable "cloudconfig_default_user" {
  type = "string"
  default = <<EOF
#cloud-config
system_info:
  default_user:
    name: elastx
EOF
}


### [Elastx Openstack] ###

provider "openstack" {
  user_name = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password = "${var.password}"
  auth_url = "https://ops.elastx.net:5000/v2.0"
}

### [General setup] ###

resource "openstack_networking_router_v2" "router" {
  name = "wk-router"
  admin_state_up = "true"
  external_gateway = "62954df1-05bb-42e5-9960-ca921cccaeeb"
}

resource "openstack_compute_keypair_v2" "demo_keypair" {
  name = "demo-keypair"
  public_key = "${file("demo_rsa.pub")}"
}

### Should be tighten up, not let the world be able to ssh
### this is only for demonstrational purposes.

resource "openstack_compute_secgroup_v2" "ssh_sg" {
  name = "wk-ssh-sg"
  description = "ssh security group"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "web_sg" {
  name = "wk-web-sg"
  description = "web security group"
  rule {
    from_port = 80
    to_port = 80
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 443
    to_port = 443
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "db_sg" {
  name = "wk-db-sg"
  description = "db security group"
  rule {
    from_port = 3306
    to_port = 3306
    ip_protocol = "tcp"
    cidr = "${openstack_networking_subnet_v2.web_subnet.cidr}"
  }
}



### [Web networking] ###

resource "openstack_networking_network_v2" "web_net" {
  name = "wk-web-net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "web_subnet" {
  name = "wk-web-subnet"
  network_id = "${openstack_networking_network_v2.web_net.id}"
  cidr = "10.0.0.0/24"
  ip_version = 4
  enable_dhcp = "true"
  dns_nameservers = ["8.8.8.8","8.8.4.4"]
}

resource "openstack_networking_router_interface_v2" "web-ext-interface" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.web_subnet.id}"
}

resource "openstack_compute_floatingip_v2" "fip" {
  count = "2"
  pool = "ext-net-01"
}

### [Web instances] ###

resource "openstack_compute_servergroup_v2" "web_srvgrp" {
  name = "wk-web-srvgrp"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "web_cluster" {
  name = "wk-web-${count.index+1}"
  count = "2"
  image_name = "centos-7-1511"
  flavor_name = "m1.tiny"
  network = { 
    uuid = "${openstack_networking_network_v2.web_net.id}"
  }
  floating_ip = "${element(openstack_compute_floatingip_v2.fip.*.address, count.index)}"
  key_pair = "${openstack_compute_keypair_v2.demo_keypair.name}"
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.web_srvgrp.id}"
  }
  security_groups = ["${openstack_compute_secgroup_v2.ssh_sg.name}","${openstack_compute_secgroup_v2.web_sg.name}"]
  user_data = "${var.cloudconfig_default_user}"
}

output "web-instances" {
  value = "${join( "," , openstack_compute_instance_v2.web_cluster.*.floating_ip ) }"
}

### [DB networking] ###

resource "openstack_networking_network_v2" "db_net" {
  name = "wk-db-net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "db_subnet" {
  name = "wk-db-subnet"
  network_id = "${openstack_networking_network_v2.db_net.id}"
  cidr = "10.0.1.0/24"
  ip_version = 4
  enable_dhcp = "true"
  dns_nameservers = ["8.8.8.8","8.8.4.4"]
}

resource "openstack_networking_router_interface_v2" "db-ext-interface" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.db_subnet.id}"
}

### [DB instances] ###

resource "openstack_compute_servergroup_v2" "db_srvgrp" {
  name = "wk-db-srvgrp"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "db_cluster" {
  name = "wk-db-${count.index+1}"
  count = "2"
  image_name = "centos-7-1511"
  flavor_name = "m1.tiny"
  network = { 
    uuid = "${openstack_networking_network_v2.db_net.id}"
  }
  key_pair = "${openstack_compute_keypair_v2.demo_keypair.name}"
  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.db_srvgrp.id}"
  }
  security_groups = ["${openstack_compute_secgroup_v2.ssh_sg.name}","${openstack_compute_secgroup_v2.db_sg.name}"]
  user_data = "${var.cloudconfig_default_user}"
}

output "db-instances" {
  value = "${join( "," , openstack_compute_instance_v2.db_cluster.*.access_ip_v4) }"
}
