locals {
  gcp_permissions = jsondecode(file("${path.module}/gcp_permissions.json"))
  orca_production_project_number = "788120191304"
}

resource "google_service_account" "orca" {
  account_id   = "orcasecurity-side-scanner"
  project      = var.project_id
  display_name = "Orca Security Side Scanning Service Account"
}

resource "google_service_account_key" "orca" {
  service_account_id = google_service_account.orca.name
}

resource "local_file" "orca" {
  content  = base64decode(google_service_account_key.orca.private_key)
  filename = "${path.module}/service_account_key_orca.json"
}

resource "google_project_iam_custom_role" "orca-custom-role" {
  role_id      = "orca_security_side_scanner_role"
  title        = "Orca Security Side Scanner Role"
  permissions  = concat(local.gcp_permissions.base, local.gcp_permissions.saas_extras)
  project      = var.project_id
}
resource "google_project_iam_member" "project-membership-1" {
  project = var.project_id
  role    = "roles/viewer"
  member  =  "serviceAccount:${google_service_account.orca.email}"
}

resource "google_project_iam_member" "project-membership-2" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  =  "serviceAccount:${google_service_account.orca.email}"
}

resource "google_project_iam_member" "project-membership-3" {
  project = var.project_id
  role    = "roles/iam.securityReviewer"
  member  =  "serviceAccount:${google_service_account.orca.email}"
}

resource "google_project_iam_member" "project-membership-4" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  =  "serviceAccount:service-${local.orca_production_project_number}@compute-system.iam.gserviceaccount.com"
}

resource "google_project_iam_binding" "project-binding-1" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/${google_project_iam_custom_role.orca-custom-role.role_id}"
  members = [
    "serviceAccount:${google_service_account.orca.email}",
  ]
}

resource "google_project_service" "service" {
  count   = length(local.gcp_permissions.api_services)
  project = var.project_id
  service = local.gcp_permissions.api_services[count.index]
}
