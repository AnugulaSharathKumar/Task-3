output "instance_private_ip" {
  description = "Private IP of the created VM"
  value       = google_compute_instance.private_vm.network_interface[0].network_ip
}

output "instance_external_ip" {
  description = "External (NAT) IP of the created VM"
  value       = google_compute_instance.private_vm.network_interface[0].access_config[0].nat_ip
}

output "vpc_name" {
  value = google_compute_network.default_vpc.name
}
