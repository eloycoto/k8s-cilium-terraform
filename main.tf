variable "credentials" {
    default="account.json"
}

variable "machine_type" {
    default = "n1-standard-1"
}

variable "network_cidr" {
    default = "172.16.0.0/16"
}

variable "network_name" {
    default = "cilium"
}

variable "nodes" {
    default = 1
}

variable "private_key_path" {
  default = "~/.ssh/google_compute_engine"
}

variable "project" {
    default = "k8s-cilium"
}

variable "region" {
  default = "europe-west1"
}

variable "token" {
    default = "258062.5d84c017c9b2796c"
}

variable "zone" {
  default = "europe-west1-b"
}


provider "google" {
  credentials = "${file("${var.credentials}")}"
  project     = "${var.project}"
  region      = "${var.zone}"
}

resource "google_compute_network" "default" {
  name                    = "cilium"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "cilium" {
  name          = "${var.network_name}"
  ip_cidr_range = "${var.network_cidr}"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.region}"
}

resource "google_compute_firewall" "ingress" {
  name    = "cilium-ingress"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "local" {
  name    = "cilium-local"
  network = "${google_compute_network.default.name}"

  source_ranges = ["172.16.0.0/16"]
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

resource "google_compute_instance" "master" {
	name         = "master"
	machine_type = "${var.machine_type}"
	zone         = "${var.zone}"
	depends_on = ["google_compute_firewall.ingress", "google_compute_firewall.local"]
	tags = ["k8s-master"]

	boot_disk {
		initialize_params {
			image = "ubuntu-os-cloud/ubuntu-1604-lts"
		}
	}

	network_interface {
        subnetwork =  "${google_compute_subnetwork.cilium.name}"
		access_config { }
	}

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("${var.private_key_path}")}"
      agent = false
    }

    provisioner "file" {
        source="scripts"
        destination="/home/ubuntu/"
    }

	provisioner "remote-exec" {
		inline = [
            "sudo chmod 777 /home/ubuntu/scripts/install.sh",
			"sudo /home/ubuntu/scripts/install.sh ${var.token}",
		]
	}

	service_account {
		scopes = ["userinfo-email", "compute-ro", "storage-ro"]
	}
}

resource "google_compute_instance" "node" {
    count        = "${var.nodes}"
	name         = "node-${count.index}"
	machine_type = "${var.machine_type}"
	zone         = "${var.zone}"


	tags = ["k8s-node-${count.index}"]

	boot_disk {
		initialize_params {
			image = "ubuntu-os-cloud/ubuntu-1604-lts"
		}
	}

	network_interface {
        subnetwork =  "${google_compute_subnetwork.cilium.name}"
		access_config { }
	}

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("${var.private_key_path}")}"
      agent = false
    }

    provisioner "file" {
        source="scripts"
        destination="/home/ubuntu/"
    }

	provisioner "remote-exec" {
		inline = [
            "sudo chmod 777 /home/ubuntu/scripts/install.sh",
			"sudo /home/ubuntu/scripts/install.sh ${var.token} ${google_compute_instance.master.network_interface.0.address}",
		]
	}

	service_account {
		scopes = ["userinfo-email", "compute-ro", "storage-ro"]
	}
}
