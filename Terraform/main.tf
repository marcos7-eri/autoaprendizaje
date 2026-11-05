data "oci_identity_availability_domains" "available" {
  compartment_id = var.parent_compartment_ocid
}

resource "oci_identity_compartment" "project" {
  compartment_id = var.parent_compartment_ocid
  name           = var.project_name
  description    = "Infraestructura de ${var.project_name} gestionada con Terraform"
}

resource "oci_core_vcn" "project" {
  compartment_id = oci_identity_compartment.project.id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.project_name}-vcn"
  dns_label      = "a1vcn"
}

resource "oci_core_internet_gateway" "project" {
  compartment_id = oci_identity_compartment.project.id
  vcn_id         = oci_core_vcn.project.id
  display_name   = "${var.project_name}-internet-gateway"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = oci_identity_compartment.project.id
  vcn_id         = oci_core_vcn.project.id
  display_name   = "${var.project_name}-public-routes"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.project.id
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = oci_identity_compartment.project.id
  vcn_id         = oci_core_vcn.project.id
  display_name   = "${var.project_name}-ssh"

  ingress_security_rules {
    protocol = "6"
    source   = var.ssh_source_cidr

    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = oci_identity_compartment.project.id
  vcn_id                     = oci_core_vcn.project.id
  cidr_block                 = var.subnet_cidr
  display_name               = "${var.project_name}-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_instance" "vm" {
  compartment_id      = oci_identity_compartment.project.id
  availability_domain = data.oci_identity_availability_domains.available.availability_domains[0].name
  display_name        = "${var.project_name}-vm"
  shape               = var.shape

  dynamic "shape_config" {
    for_each = var.shape == "VM.Standard.A1.Flex" ? [1] : []
    content {
      ocpus         = 1
      memory_in_gbs = 6
    }
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
  }
}

