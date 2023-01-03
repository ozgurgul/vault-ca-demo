
#
# Role for server certs
#
# Use pki-kafka-int-ca-${each.key}/roles/<name> endpoint to create and update roles
resource "vault_pki_secret_backend_role" "role-server-cer" {
  for_each = toset(local.kafka_pki_path)
    backend = vault_mount.kafka_pki_int[each.key].path
    name = "server-cert-for-${each.key}-${var.server_cert_domain}"
    max_ttl = local.default_2y_in_sec # 2 years in sec
    ttl = local.default_30d_in_sec # 30 days in sec
    allow_ip_sans = true
    key_type = "rsa"
    key_bits = "4096"
    key_usage = ["DigitalSignature","KeyAgreement","KeyEncipherment"]
    allow_any_name = false
    allow_localhost = true
    allowed_domains = [ var.server_cert_domain ]
    allow_bare_domains = false
    allow_subdomains = true
    allow_glob_domains = false
    enforce_hostnames = true
    server_flag = true
    client_flag = true
    ou = ["development"]
    organization = ["My Company"]
    country = ["GB"]
    locality = ["Angel Lane"]
    no_store = true

}

# Use pki-kafka-int-ca/roles/<name> endpoint to create and update roles
resource "vault_pki_secret_backend_role" "vault-client-cert" {
  for_each = toset(local.kafka_pki_path)
    backend = vault_mount.kafka_pki_int[each.key].path
    name = "client-cert-for-${each.key}-${var.client_cert_domain}"
    allowed_domains = [ var.client_cert_domain ]
    allow_localhost = true
    allow_subdomains = true
    allow_glob_domains = false
    allow_bare_domains = true # needed for email address verification
    allow_any_name = false
    enforce_hostnames = true
    allow_ip_sans = true
    #allowed_other_sans = ["1.2.840.113549.1.9.1;utf8:emailAddress"]
    server_flag = true
    client_flag = true
    require_cn = true
    use_csr_common_name = true
    key_usage = ["DigitalSignature","KeyAgreement","KeyEncipherment"]
    ou = ["development"]
    organization = ["My Services"]
    country = ["UK"]
    locality = ["London"]
    max_ttl = 30 * 24 * 60 * 60 # 30 days
    ttl = 30 * 24 * 60 * 60 # 30 days
    no_store = true

}
