# When using namespaces from the root namespace, need to append the namespace to the policy when installing in the root namespace.
# If using KV v1
path "secret/finance/ar-app/*" {
    capabilities = ["read", "list"]
}

# If using KV v2
path "secret/data/finance/ar-app/*" {
    capabilities = ["read", "list"]
}

path "secret/metadata/finance/ar-app/*" {
    capabilities = ["read", "list"]
}
