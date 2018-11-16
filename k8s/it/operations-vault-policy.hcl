# When using namespaces from the root namespace, need to append the namespace to the policy when installing in the root namespace.
# If using KV v1
# Non-namespaced policy
path "secret/operations/*" {
    capabilities = ["read", "list"]
}

# Namespaced policy
path "it/secret/operations/*" {
    capabilities = ["read", "list"]
}

# If using KV v2
# Non-Namespaced policy
path "secret/data/operations/*" {
    capabilities = ["read", "list"]
}

# Namespaced policy
path "it/secret/data/operations/*" {
    capabilities = ["read", "list"]
}
