cat >> ${NAMESPACE}/${APP}.yaml << EOL
---
apiVersion: v1
kind: Pod
metadata:
  name: vault-agent-example
spec:
  serviceAccountName: operations
  restartPolicy: Never
  volumes:
    - name: vault-token
      emptyDir:
        medium: Memory
    - name: config
      configMap:
        name: example-vault-agent-config
        items:
          - key: vault-agent-config.hcl
            path: vault-agent-config.hcl

          - key: consul-template-config-kv-v1.hcl
            path: consul-template-config.hcl
    - name: shared-data
      emptyDir: {}

  containers:
    # Generic container run in the context of vault agent
    - name: vault-agent-auth
      image: grovemountain/hashicorp_agent_tools:latest

      volumeMounts:
        - name: vault-token
          mountPath: /home/vault
        - name: config
          mountPath: /etc/vault

      # This assumes Vault running on local host and K8s running in Minikube using VirtualBox
      env:
        - name: VAULT_ADDR
          value: ${VAULT_ADDR}
        - name: VAULT_K8S_AUTH_MOUNT
          value: kubernetes
        - name: VAULT_K8S_AUTH_ROLE
          value: ${NAMESPACE}-${APP}
        - name: LOG_LEVEL
          value: info
      # Run the Vault agent
      args:
        [
          "agent",
          "-config=/etc/vault/vault-agent-config.hcl",
          "-log-level=\${LOG_LEVEL}",
        ]

    # Generic tools container but used in the context of consul template here.   
    - name: consul-template
      image: grovemountain/hashicorp_agent_tools:latest
      imagePullPolicy: Always

      volumeMounts:
        - name: vault-token
          mountPath: /home/vault
        - name: config
          mountPath: /etc/consul-template
        - name: shared-data
          mountPath: /etc/secrets

      env:
        - name: HOME
          value: /home/vault
        - name: VAULT_ADDR
          value: ${VAULT_ADDR}
        - name: VAULT_K8S_AUTH_MOUNT
          value: kubernetes
        - name: VAULT_K8S_AUTH_ROLE
          value: ${NAMESPACE}-${APP}
        - name: LOG_LEVEL
          value: info

      # Consul-Template looks in \$HOME/.vault-token, \$VAULT_TOKEN, or -vault-token (via CLI)
      args:
        [
          "-config=/etc/consul-template/consul-template-config.hcl",
          "-log-level=\${LOG_LEVEL}",
        ]

    # Nginx container
    - name: nginx-container
      image: nginx

      ports:
        - containerPort: 80

      volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
EOL
