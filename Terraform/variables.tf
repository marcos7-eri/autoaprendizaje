variable "parent_compartment_ocid" {
  description = "OCID del tenancy o compartment donde se creará el compartment del proyecto."
  type        = string

  validation {
    condition     = startswith(var.parent_compartment_ocid, "ocid1.tenancy.") || startswith(var.parent_compartment_ocid, "ocid1.compartment.")
    error_message = "Proporciona un OCID de tenancy o compartment válido."
  }
}

variable "project_name" {
  description = "Prefijo estable para los recursos OCI."
  type        = string
  default     = "autoaprendizaje1"
}

variable "image_ocid" {
  description = "OCID de una imagen compatible con la región y el shape elegido."
  type        = string

  validation {
    condition     = startswith(var.image_ocid, "ocid1.image.")
    error_message = "Proporciona un OCID de imagen válido."
  }
}

variable "shape" {
  description = "Shape de la VM; confirmar su disponibilidad y precio en la región."
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "ssh_public_key" {
  description = "Contenido de la clave pública SSH que accederá a la VM."
  type        = string

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-[^ ]+) [A-Za-z0-9+/=]+", trimspace(var.ssh_public_key)))
    error_message = "Proporciona una clave pública SSH válida."
  }
}

variable "ssh_source_cidr" {
  description = "CIDR autorizado a conectarse por SSH; usa tu IP pública con /32."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_source_cidr, 0))
    error_message = "Proporciona un CIDR válido, por ejemplo 203.0.113.10/32."
  }
}

variable "vcn_cidr" {
  description = "Bloque CIDR de la VCN."
  type        = string
  default     = "10.23.0.0/20"
}

variable "subnet_cidr" {
  description = "Bloque CIDR de la subred pública."
  type        = string
  default     = "10.23.11.0/24"
}

