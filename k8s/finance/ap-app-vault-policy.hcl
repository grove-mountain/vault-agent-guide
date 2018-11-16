# If using KV v1
path "secret/finance/ap-app/*" {
    capabilities = ["read", "list"]
}

# If using KV v2
path "secret/data/finance/ap-app/*" {
    capabilities = ["read", "list"]
}

path "secret/metadata/finance/ap-app/*" {
    capabilities = ["read", "list"]
}
