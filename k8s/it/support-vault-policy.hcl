# When using namespaces from the root namespace, need to append the namespace to the policy when installing in the root namespace.
# If using KV v1
# Non-namespaced policy
path "k8s-secret/it/support/*" {
    capabilities = ["read", "list"]
}

# If using KV v2
# Non-Namespaced policy
path "k8s-secret/data/it/support/*" {
    capabilities = ["read", "list"]
}

# enabling for GUI access
path "k8s-secret/metadata/it/support/*" {
    capabilities = ["read", "list"]
}
