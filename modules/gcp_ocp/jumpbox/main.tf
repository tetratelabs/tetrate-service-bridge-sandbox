## Public DNS Zone and domain validation

# resource google_project_service siteverification {
#   service = "siteverification.googleapis.com"
# }

# data "googlesiteverification_dns_token" "domain" {
#   domain     = var.domain_name
#   depends_on = [google_project_service.siteverification]
# }

# resource "google_dns_record_set" "domain" {
#   managed_zone = google_dns_managed_zone.domain.name
#   name         = "${data.googlesiteverification_dns_token.domain.record_name}."
#   rrdatas      = [data.googlesiteverification_dns_token.domain.record_value]
#   type         = data.googlesiteverification_dns_token.domain.record_type
#   ttl          = 60
# }

# resource "googlesiteverification_dns" "domain" {
#   domain     = var.domain_name
#   token      = data.googlesiteverification_dns_token.domain.record_value
#   depends_on = [aws_route53_record.domain_ns_records]
# }

# data "aws_route53_zone" "parent" {
#   name = "${local.parent_domain_name}."
# }

# resource "aws_route53_record" "domain_ns_records" {
#   zone_id = data.aws_route53_zone.parent.zone_id
#   name    = "${var.domain_name}."
#   type    = "NS"
#   ttl     = "60"
#   records = google_dns_managed_zone.domain.name_servers
# }

resource "google_dns_managed_zone" "ocp" {
  name       = "ocp-gcp-cx-tetrate-info"
  dns_name   = "ocp.gcp.cx.tetrate.info."
  project    = var.project_id
  depends_on = [google_project_service.project-dns]
}

data "google_dns_managed_zone" "zone" {
  project = "dns-terraform-sandbox"
  name    = "gcp-cx-tetrate-info"
}

data "dns_ns_record_set" "ocp" {
  host = var.address
}

resource "google_dns_record_set" "ocp_ns" {
  managed_zone = data.google_dns_managed_zone.zone.name
  name         = google_dns_managed_zone.ocp.dns_name
  type         = "NS"
  ttl          = 300

  rrdatas = google_dns_managed_zone.ocp.name_servers
}

data "google_compute_subnetwork" "wait_for_compute_apis_to_be_ready" {
  self_link = var.vpc_subnet
  project   = var.project_id
  region    = var.region
}

# doing dependency for google_compute_zones data to wait for compute api readiness... or expose zone from gcp_base module...
data "google_compute_zones" "available" {
  project = var.project_id
  region  = data.google_compute_subnetwork.wait_for_compute_apis_to_be_ready.region
}

# data "google_compute_default_service_account" "default" {
#   project = var.project_id
#   depends_on = [
#     data.google_compute_subnetwork.wait_for_compute_apis_to_be_ready
#   ]
# }

resource "google_service_account" "myaccount" {
  project      = var.project_id
  account_id   = "myaccount"
  display_name = "My Service Account"
  # depends_on = [
  #   data.google_compute_subnetwork.wait_for_compute_apis_to_be_ready
  # ]
}

resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.myaccount.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

resource "google_project_iam_member" "compute_instanceAdmin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

resource "google_project_iam_member" "compute_networkAdmin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

resource "google_project_iam_member" "compute_securityAdmin" {
  project = var.project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

resource "google_project_iam_member" "iam_serviceAccountUser" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

resource "google_project_iam_member" "compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

resource "google_project_iam_member" "iam_serviceAccountKeyAdmin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountKeyAdmin"
  member  = "serviceAccount:${google_service_account.myaccount.email}"
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# custom APIs needed for OCP on GCP
resource "google_project_service" "project-compute" {
  project                    = var.project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-cloudapis" {
  project                    = var.project_id
  service                    = "cloudapis.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-cloudresourcemanager" {
  project                    = var.project_id
  service                    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-dns" {
  project                    = var.project_id
  service                    = "dns.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-iamcredentials" {
  project                    = var.project_id
  service                    = "iamcredentials.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-iam" {
  project                    = var.project_id
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-servicemanagement" {
  project                    = var.project_id
  service                    = "servicemanagement.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-serviceusage" {
  project                    = var.project_id
  service                    = "serviceusage.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-storage-api" {
  project                    = var.project_id
  service                    = "storage-api.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "project-storage-component" {
  project                    = var.project_id
  service                    = "storage-component.googleapis.com"
  disable_dependent_services = true
}

## jumpbox resource def
resource "google_compute_instance" "jumpbox" {
  project      = var.project_id
  name         = "${var.name_prefix}-jumpbox"
  machine_type = "n1-standard-2"
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2204-lts"
    }
  }

  network_interface {
    network    = var.vpc_id
    subnetwork = var.vpc_subnet
    access_config {
      // Ephemeral public IP
    }
  }

  # image support required for user-data https://cloud.google.com/container-optimized-os/docs/how-to/create-configure-instance
  # shortcut for demo purposes

  #metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq cloud-init; sudo curl -o /etc/cloud/cloud.cfg.d/jumpbox.userdata  http://metadata/computeMetadata/v1/instance/attributes/user-data -H'Metadata-Flavor:Google'; sudo cloud-init -d init; sudo cloud-init -d modules --mode final; /opt/bootstrap.sh"

  metadata = {
    user-data = templatefile("${path.module}/jumpbox.userdata", {
      jumpbox_username        = var.jumpbox_username
      tsb_version             = var.tsb_version
      tsb_image_sync_username = var.tsb_image_sync_username
      tsb_image_sync_apikey   = var.tsb_image_sync_apikey
      docker_login            = "gcloud auth configure-docker -q"
      registry                = var.registry
      pubkey                  = tls_private_key.generated.public_key_openssh
      gcp_dns_domain          = var.gcp_dns_domain
      ocp_pull_secret         = jsonencode({})
      cluster_name            = var.cluster_name
      project_id              = var.project_id
      region                  = var.region
      # ssh_key                 = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
      ssh_key                 = var.ssh_key
      google_service_account  = jsonencode("${base64decode(google_service_account_key.mykey.private_key)}")
      # google_service_account = var.google_service_account
    })
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.myaccount.email
    scopes = ["cloud-platform"]
  }
  depends_on = [
    google_service_account_key.mykey
  ]
}

## Files section ---

resource "local_file" "tsbadmin_pem" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${var.output_path}/${var.name_prefix}-gcp-${var.jumpbox_username}.pem"
  depends_on      = [tls_private_key.generated]
  file_permission = "0600"
}

/* resource "local_file" "ssh_jumpbox" {
  content         = "/bin/sh gcloud compute ssh ${google_compute_instance.jumpbox.name} --project=${var.project_id} --zone=${data.google_compute_zones.available.names[0]}"
  filename        = "ssh-to-gcp-jumpbox.sh"
  file_permission = "0755"
} */

resource "local_file" "ssh_jumpbox" {
  content         = "ssh -i ${var.name_prefix}-gcp-${var.jumpbox_username}.pem -l ${var.jumpbox_username} ${google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip}"
  filename        = "${var.output_path}/ssh-to-gcp-${var.name_prefix}-jumpbox.sh"
  file_permission = "0755"
}

resource "local_file" "google_service_account" {
  content         = base64decode(google_service_account_key.mykey.private_key)
  filename        = "${var.output_path}/${var.name_prefix}-gcp-ocp-sa-${var.jumpbox_username}.json"
  file_permission = "0600"
}
