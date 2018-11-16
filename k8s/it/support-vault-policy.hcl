# When using namespaces from the root namespace, need to append the namespace to the policy when installing in the root namespace.
# If using KV v1
# Non-namespaced policy
path "secret/support/*" {
    capabilities = ["read", "list"]
}

# Namespaced policy
path "it/secret/support/*" {
    capabilities = ["read", "list"]
}

# If using KV v2
# Non-Namespaced policy
path "secret/data/support/*" {
    capabilities = ["read", "list"]
}

# Namespaced policy
path "it/secret/data/support/*" {
    capabilities = ["read", "list"]
}
