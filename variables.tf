variable server_cert_domain {
    description = "We create a role to create client certs, what DNS domain will these certs be in"
    default = "myservices.net"
}

variable client_cert_domain {
    description = "Allowed Domains for Client Cert"
    default = "myservices.net"
}

variable vault_address {
    description = "VAULT_ADDR"
    default = "http://127.0.0.1:8200"
}