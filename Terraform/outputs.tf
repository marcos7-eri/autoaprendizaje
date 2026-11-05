output "compartment_id" {
  description = "OCID del compartment creado."
  value       = oci_identity_compartment.project.id
}

output "vcn_id" {
  description = "OCID de la VCN."
  value       = oci_core_vcn.project.id
}

output "instance_id" {
  description = "OCID de la VM."
  value       = oci_core_instance.vm.id
}

output "instance_public_ip" {
  description = "IP pública de la VM."
  value       = oci_core_instance.vm.public_ip
}

