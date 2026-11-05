terraform {
  required_version = ">= 1.12.0, < 1.17.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "8.29.0"
    }
  }

  backend "oci" {
    key = "autoaprendizaje1/terraform.tfstate"
  }
}

