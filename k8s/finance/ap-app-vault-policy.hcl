# If using KV v1
path "k8s-secret/finance/ap-app/*" {
    capabilities = ["read", "list"]
}

# If using KV v2
path "k8s-secret/data/finance/ap-app/*" {
    capabilities = ["read", "list"]
}

path "k8s-secret/metadata/finance/ap-app/*" {
    capabilities = ["read", "list"]
}
