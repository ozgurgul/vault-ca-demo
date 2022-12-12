terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }

    vault = {
      source = "hashicorp/vault"
      version = "3.11.0"
    }

    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
  }
}

provider "tls" {
  # Configuration options
}

provider "vault" {
  # Configuration options
  address = "http://127.0.0.1:8200"
  # It is strongly recommended to configure this provider through the
  # environment variables:
  #   - VAULT_ADDR
  #   - VAULT_TOKEN
  #   - VAULT_CACERT
  #   - VAULT_CAPATH
  #   - etc.
}

provider "local" {
  # Configuration options
}