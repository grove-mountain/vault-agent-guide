# When using namespaces from the root namespace, need to append the namespace to the policy when installing in the root namespace.
# If using KV v1
# Non-namespaced policy
path "secret/it/operations/*" {
    capabilities = ["read", "list"]
}

# If using KV v2
# Non-Namespaced policy
path "secret/data/it/operations/*" {
    capabilities = ["read", "list"]
}

path "secret/metadata/it/operations/*" {
    capabilities = ["read", "list"]
}
