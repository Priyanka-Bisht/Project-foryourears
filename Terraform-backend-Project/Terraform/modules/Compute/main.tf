##################### instance template ########################
data "google_compute_image" "custom_image" {
  name    = var.custom_image_name  # Replace with the name of your image
  #family  = "pipelineimage"  # If your image has no family, set this to null
  project = var.project_id
}

data "google_service_account" "service_account" {
  account_id   = var.account_id  # Replace with the name of your image
}

# Create a custom instance template
resource "google_compute_instance_template" "my_instance_template" {
  name        = var.instance_template_name
  description = var.instance_template_description

  # Specify the custom image
  disk {
    source_image = data.google_compute_image.custom_image.self_link
  }

  network_interface {
    network = var.network_name
    subnetwork = var.subnetwork_name
  }
  


  # Other instance configuration options as needed
  machine_type = var.machine_type

  # Specify the service account for the instance template
  service_account {
    email  = data.google_service_account.service_account.email
    scopes = ["https://www.googleapis.com/auth/compute", "https://www.googleapis.com/auth/devstorage.full_control"]  # Add the necessary scopes for your use case
  }
}

############### Auto-scaler for instance_group_manager ########################

resource "google_compute_autoscaler" "instance_group" {
  name   = var.autoscaler_name
  zone   = var.zone
  target = google_compute_instance_group_manager.my_instance_group.id

  autoscaling_policy {
    max_replicas    = var.autoscaler_max_replicas
    min_replicas    = var.autoscaler_min_replicas
    cooldown_period = var.autoscaler_cooldown_period

    cpu_utilization {
      target = var.cpu_utilization_target
    }
  }
}

############# Create an instance group manager from the instance template ################################

resource "google_compute_instance_group_manager" "my_instance_group" {
  name        = var.instance_group_name
  description = var.instance_group_description
  zone        = var.zone # Change to your desired zone

  base_instance_name = var.instance_group_base_name
  target_size       = var.instance_group_target_size # Set the desired target size
  named_port {
    name = "http"
    port = 80 # Update this to match the port your application is listening on
  }

  version {
    instance_template = google_compute_instance_template.my_instance_template.id

  }

}


