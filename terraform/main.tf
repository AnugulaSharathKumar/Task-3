provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_network" "default_vpc" {
  name                    = "default-vpc"
  auto_create_subnetworks = false
  description             = "Custom VPC for project"
}

resource "google_compute_subnetwork" "mumbai_subnet" {
  name                     = "mumbai-subnet"
  ip_cidr_range            = "10.10.0.0/24"
  region                   = var.region
  network                  = google_compute_network.default_vpc.self_link
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal"
  network = google_compute_network.default_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.10.0.0/24"]
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.default_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
  description   = "Allow SSH from the internet to instances with tag=ssh"
}

resource "google_compute_instance" "private_vm" {
  name         = "private-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mumbai_subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys = var.ssh_keys
    startup-script = <<-EOF
      #!/usr/bin/env bash
      set -xe

      # install nginx and prerequisites
      apt-get update
      apt-get install -y nginx curl jq tar
      systemctl enable --now nginx

      # create runner directory
      RUN_DIR=/opt/actions-runner
      mkdir -p "$RUN_DIR"
      cd /opt

      # fetch latest runner tarball for linux x64
      ASSET_URL=$(curl -sS https://api.github.com/repos/actions/runner/releases/latest | jq -r '.assets[] | select(.name|test("linux-x64")) | .browser_download_url')
      curl -sL "$ASSET_URL" -o actions-runner.tar.gz
      tar xzf actions-runner.tar.gz -C "$RUN_DIR"
      chown -R root:root "$RUN_DIR"

      # configure runner (requires registration token provided via Terraform variable)
      cd "$RUN_DIR"
      ./config.sh --unattended --url "https://github.com/${var.github_owner_repo}" --token "${var.github_runner_token}" --name "private-vm" --work _work --labels self-hosted,linux

      # create systemd service to tie runner lifecycle to nginx
      cat > /etc/systemd/system/github-runner.service <<EOL
[Unit]
Description=GitHub Actions Runner
After=network.target nginx.service
Wants=nginx.service
BindsTo=nginx.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

      systemctl daemon-reload
      systemctl enable --now github-runner.service
    EOF
  }

  tags = ["private", "ssh"]
}
