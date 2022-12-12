## Enable the PKI Secrets Engine
# Enables and configures PKI secrets engine.
resource "vault_mount" "kafka_root" {
    path = "pki-kafka-root-ca"
    type = "pki"
    description = "Kafka Root Certificate Authority"
    default_lease_ttl_seconds = local.default_1y_in_sec
    max_lease_ttl_seconds = local.default_5y_in_sec
}

## Set URL Configuration
# Modify the mount point and set URLs for the issuer and crl.
# Data written to: pki-kafka-root-ca/config/urls
resource "vault_pki_secret_backend_config_urls" "config_urls_root_ca" {
  depends_on = [ vault_mount.kafka_root ]
  backend              = vault_mount.kafka_root.path
  #issuing_certificates = ["https://vault.core.${var.server_cert_domain}:8200/v1/pki-kafka-root-ca/ca"]
  #crl_distribution_points= ["https://vault.core.${var.server_cert_domain}:8200/v1/pki-kafka-root-ca/crl"]
  issuing_certificates = ["http://127.0.0.1:8200/v1/${vault_mount.kafka_root.path}/ca"]
  crl_distribution_points= ["http://127.0.0.1:8200/v1/${vault_mount.kafka_root.path}/crl"]
}

# if you want to create the root cert in VAULT and never expose the
# private key to the local machine use this route.  However your
# CA infrastructure is now tied to vault and pretty much the server
# you created the CA on.
resource "vault_pki_secret_backend_root_cert" "ca-cert" {
  depends_on = [ vault_pki_secret_backend_config_urls.config_urls_root_ca ]
  backend = vault_mount.kafka_root.path

  type = "exported"
  common_name = "${var.server_cert_domain} Root CA"
  ttl = local.default_15y_in_sec #15 Years
  format = "pem"
  private_key_format = "der"
  key_type = "rsa"
  key_bits = "2048"
  exclude_cn_from_sans = true
  ou = "Development"
  organization = "Clinical"

}

resource local_sensitive_file ca_file_vault {
    content = vault_pki_secret_backend_root_cert.ca-cert.certificate
    filename = "${path.root}/output/certs/kafka_ca_cert.pem"
    file_permission = "0400"
}


# Create a private key for use with the Root CA.
resource tls_private_key ca_key {
   algorithm = "RSA"
   rsa_bits = 4096
}
# This is a highly sensitive output of this process.
resource local_sensitive_file private_key {
    content = tls_private_key.ca_key.private_key_pem
    filename = "${path.root}/output/root_ca/ca_key.pem"
    file_permission = "0400"
}

#
# Create a Self Signed Root Certificate Authority
#
resource tls_self_signed_cert ca_cert {
   private_key_pem = tls_private_key.ca_key.private_key_pem

   subject {
     common_name = "${var.server_cert_domain} Root CA"
     organization = "MC Inc"
     organizational_unit = "Development"
     street_address = ["Angel Lane"]
     locality = "London"
     country = "UK"
     postal_code = "E1 1AA"

   }

   validity_period_hours = local.default_20y_in_hr
   allowed_uses = [
     "cert_signing",
     "crl_signing"
   ]
   is_ca_certificate = true

}

resource local_sensitive_file ca_file {
    content = tls_self_signed_cert.ca_cert.cert_pem
    filename = "${path.root}/output/root_ca/ca_cert.pem"
    file_permission = "0400"
}
# This PEM bundle is not like most others.  Most PEM bundles are a chain of Certificate Authority Certs.
# This bundle is the Private Key (first), followed by the the Certificate.
resource local_sensitive_file ca_pem_bundle {
    content = "${tls_private_key.ca_key.private_key_pem}${tls_self_signed_cert.ca_cert.cert_pem}"
    filename = "${path.root}/output/root_ca/ca_cert_key_bundle.pem"
    file_permission = "0400"
}

# Take the Root CA certificate that we have created and store it in
# the mount point pki-kafka-root-ca.  The ca_pem_bundle in this case is
# the Certificate we generated and the key for it.
resource "vault_pki_secret_backend_config_ca" "ca_config" {
  depends_on = [ vault_mount.kafka_root, tls_private_key.ca_key]
  backend  = vault_mount.kafka_root.path
  pem_bundle = local_sensitive_file.ca_pem_bundle.content
}

