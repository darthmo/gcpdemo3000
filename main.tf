provider "google" {
project = var.project_id
region = var.region
zone = var.zone
impersonate_service_account = var.tf_service_account
}


resource "google_compute_firewall" "allow-healthchecks" {
  name    = "allow-healthchecks"
  network = "default"
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16",
                     "130.211.0.0/22"]
 }

 resource "google_compute_firewall" "allow-internet" {
   name    = "allow-internet"
   network = "default"
   direction = "EGRESS"
   allow {
     protocol = "tcp"
     ports    = ["80"]
   }

  }


//Web servers

resource "google_compute_instance" "vm1" {
  name         = "webserver-us"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  tags = ["web-server",
          "http-server",
          "https-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  metadata ={
  startup-script = <<-EOF
                    #! /bin/bash
                    apt-get update
                    apt-get install apache2 -y
                    echo "Page served from: US-EAST1" | tee /var/www/html/index.html
                    systemctl restart apache2"
                    EOF
 }
}

resource "google_compute_instance" "vm2" {
  name         = "webserver-eu"
  machine_type = "e2-medium"
  zone         = "europe-west3-a"
  tags = ["web-server",
          "http-server",
          "https-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  metadata ={
  startup-script = <<-EOF
                    #! /bin/bash
                    apt-get update
                    apt-get install apache2 -y
                    echo "Page served from: EU-WEST" | tee /var/www/html/index.html
                    systemctl restart apache2"
                    EOF
 }
}

//Instance groups

resource "google_compute_instance_group" "webserver-us" {
  name        = "us-webserver-instance-group"

  instances = [
    google_compute_instance.vm1.id,
  ]
  zone = "us-central1-a"
  named_port {
  name = "http"
  port = "80"
}
}

resource "google_compute_instance_group" "webserver-eu" {
  name        = "eu-webserver-instance-group"

  instances = [
    google_compute_instance.vm2.id,
  ]
  zone = "europe-west3-a"
  named_port {
  name = "http"
  port = "80"
}
}

//Health Check

resource "google_compute_health_check" "healthcheck1" {
  name = "healthcheck80"

  timeout_sec        = 5
  check_interval_sec = 5

  tcp_health_check {
    port = "80"
  }
}

//backend

resource "google_compute_backend_service" "default" {
  name          = "webserver-backend"
  health_checks = [google_compute_health_check.healthcheck1.id]
  backend {
    group = google_compute_instance_group.webserver-us.id
  }
  backend {
    group = google_compute_instance_group.webserver-eu.id
  }
}

//URL Map

resource "google_compute_url_map" "urlmap" {
  name        = "webserver-glb"
  default_service = google_compute_backend_service.default.id
}

//http proxy

resource "google_compute_target_http_proxy" "default" {
  name    = "webserver-glb-target-proxy"
  url_map = google_compute_url_map.urlmap.id
}

//Forwarding Rule

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "webserver-frontend"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
}

// Test vms

resource "google_compute_instance" "vm3" {
  name         = "testvm1"
  machine_type = "e2-medium"
  zone         = "us-west2-a"
  tags = ["uservm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }
  network_interface {
    network = "default"
    # access_config {
    # }
  }
}

resource "google_compute_instance" "vm4" {
  name         = "testvm2"
  machine_type = "e2-medium"
  zone         = "europe-west3-c"
  tags = ["uservm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }
  network_interface {
    network = "default"
    # access_config {
    # }
  }
}
