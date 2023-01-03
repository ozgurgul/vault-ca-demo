# Create a mount point for the Intermediate CA.
resource "vault_mount" "kafka_pki_int" {
    for_each = toset(local.kafka_pki_path)
        type = "pki"
        path = "pki-kafka-int-ca-${each.key}"
        description = "PKI engine hosting Intermediate Authority for ${each.key}.${var.server_cert_domain} on kafka-int-ca-${each.key}"
        default_lease_ttl_seconds = local.default_2y_in_sec # 2 years
        max_lease_ttl_seconds = local.default_2y_in_sec # 63072000 # 2 years
}
#
# Step 1
#
# Create a CSR (Certificate Signing Request)
# Behind the scenes this creates a new private key, that has signed the
# CSR.  Later on, when we store the signed Intermediate Cert, that
# certificate must match the Private Key generated here.
# I don't see an obvious way to use these APIs to put an intermediate cert
# into vault that was generated outside of vault.
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on = [ vault_mount.kafka_pki_int ]
  for_each = toset(local.kafka_pki_path)
    backend = vault_mount.kafka_pki_int[each.key].path
    #backend = vault_mount.root.path
    type = "internal"
    # This appears to be overwritten when the CA signs this cert, I'm not sure
    # the importance of common_name here.
    common_name = "${each.key}.${var.server_cert_domain} Intermediate Certificate"
    key_type = "rsa"
    key_bits = "4096"
    ou           = "${var.server_cert_domain}"
    organization = "MC Intermediate"
    country      = "UK"
    locality     = "London"
    format       = "pem"
    private_key_format = "der"
}
#
# Step 2
#
# Have the Root CA Sign our CSR
resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  depends_on = [
      vault_pki_secret_backend_intermediate_cert_request.intermediate,
      vault_pki_secret_backend_config_ca.ca_config
      ]
  for_each = toset(local.kafka_pki_path)
    backend = vault_mount.kafka_root.path

    csr = vault_pki_secret_backend_intermediate_cert_request.intermediate[each.key].csr
    common_name = "${each.key}.${var.server_cert_domain} Intermediate Certificate"
    exclude_cn_from_sans = true
    ou = "Kafka Development"
    organization = "myservices.net"
    max_path_length       = 1
    # Note that I am asking for 5 years here, since the vault_mount.kafka_root has a max_lease_ttl of 5 years
    # this 5 year request is shortened to 5.
    ttl                   = local.default_5y_in_sec  # 5 years

}

## Set URL Configuration
# Modify the mount point and set URLs for the issuer and crl.
# Data written to: pki-kafka-root-ca/config/urls
resource "vault_pki_secret_backend_config_urls" "config_urls_int_ca" {
  depends_on = [ vault_mount.kafka_pki_int ]
  for_each = toset(local.kafka_pki_path)
    backend              = vault_mount.kafka_pki_int[each.key].path
    #issuing_certificates = ["https://vault.core.${var.server_cert_domain}:8200/v1/pki-kafka-int-ca/ca"]
    #crl_distribution_points= ["https://vault.core.${var.server_cert_domain}:8200/v1/pki-kafka-int-ca/crl"]
    issuing_certificates = ["http://127.0.0.1:8200/v1/${vault_mount.kafka_pki_int[each.key].path}/ca"]
    crl_distribution_points= ["http://127.0.0.1:8200/v1/${vault_mount.kafka_pki_int[each.key].path}/crl"]
}


# Save the public part of the certifiate and store it in a local file.  Note that I never extract
# the private key out of vault, so 1) their is no risk of disclosing private key 2) this
# intermediate cert is bound to vault.
resource local_sensitive_file signed_intermediate {
    for_each = toset(local.kafka_pki_path)
        content = vault_pki_secret_backend_root_sign_intermediate.intermediate[each.key].certificate
        filename = "${path.root}/output/int_ca/${each.key}/int_cert.pem"
        file_permission = "0400"
}

#
# Step 3
#
# Now that CSR is processed and we have a signed cert
# Put the Certificate, and The Root CA into the backend
# mount point.  IF you do not put the CA in here, the
# chained_ca output of a generated cert will only be
# the intermedaite cert and not the whole chain.
resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
 depends_on  = [ vault_pki_secret_backend_root_sign_intermediate.intermediate ]
 for_each = toset(local.kafka_pki_path)
    backend = vault_mount.kafka_pki_int[each.key].path

    #certificate = "${vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate}\n${tls_self_signed_cert.ca_cert.cert_pem}"
    certificate = format("%s\n%s", vault_pki_secret_backend_root_sign_intermediate.intermediate[each.key].certificate, tls_self_signed_cert.ca_cert.cert_pem)
    # certificate = format("%s\n%s", vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate, file("\${path.module}/cacerts/test_org_v1_ica1_v1.crt"))
}

# Terraform outputs if you want to do something more with these certs in terraform.
output "ca_cert_chain"  {
    #value = vault_pki_secret_backend_root_sign_intermediate.intermediate.ca_chain
    value = local.output_ca_chain_key
}

output "intermediate_ca" {
    value = local.output_certificate_key
    #value = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

output "intermediate_key"  {
    sensitive = true
    #value = vault_pki_secret_backend_intermediate_cert_request.intermediate.private_key
    value = local.output_private_key
}