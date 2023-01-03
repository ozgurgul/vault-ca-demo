locals {
 default_15y_in_sec  = 15 * 365 * 24 * 60 * 60 #
 default_5y_in_sec   =  5 * 365 * 24 * 60 * 60 # 157680000
 default_3y_in_sec   =  3 * 365 * 24 * 60 * 60 # 94608000
 default_2y_in_sec   =  2 * 365 * 24 * 60 * 60 # 63072000
 default_1y_in_sec   =      365 * 24 * 60 * 60 # 31536000
 default_30d_in_sec  =       30 * 24 * 60 * 60 # 30 days in sec
 default_1hr_in_sec  =                 60 * 60 # 3600
 default_20y_in_hr   = 20 * 365 * 24           # 175200

 kafka_pki_path = [ "sbox" , "nprod", "prod" ]

 output_ca_chain_key = [for k in vault_pki_secret_backend_root_sign_intermediate.intermediate : k.ca_chain]
 output_certificate_key = [for k in vault_pki_secret_backend_root_sign_intermediate.intermediate : k.certificate]
 output_private_key = [for k in vault_pki_secret_backend_intermediate_cert_request.intermediate : k.private_key]

}