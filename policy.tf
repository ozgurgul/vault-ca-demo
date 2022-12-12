# create a policy
resource "vault_policy" "kafka" {
  name = "vault_kafka_policy"

  policy = data.vault_policy_document.list_update_secrets.hcl
}

data "vault_policy_document" "list_update_secrets" {
  rule {
    path         = "secret/pki-kafka-*"
    capabilities = ["list","update"]
    description  = "Allow List and Update on secrets/pki-kafka* "
  }
}
