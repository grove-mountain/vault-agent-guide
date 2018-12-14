. ../scripts/env.sh

yellow "This assumes you already have a working copy of Kubernetes"
yellow "This assumes you already have a working copy of Vault with \$VAULT_ADDR and \$VAULT_TOKEN defined"

# Allows you to use an environment variable for k8s namespaces
#green "Creating shortcut for kubectl with namespace identifier"
# alias kctl="kubectl --namespace=\${NAMESPACE} "

green "This is the service account used for verifying JWT tokens coming from K8s pod requests via Vault"

pe "kubectl create sa vault-auth"
pe "kubectl apply -f vault-auth-cluster-role-binding.yml"


green "Grabbing all the data needed to configure the kubernetes auth method to connect to K8s"
# Assuming the first secret is the one we want to use
export VAULT_SA_SECRET_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[0]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_SECRET_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(minikube ip)

cat << EOL
export K8S_HOST=${K8S_HOST}

export VAULT_SA_SECRET_NAME=${VAULT_SA_SECRET_NAME}

export SA_JWT_TOKEN=${SA_JWT_TOKEN}

export SA_CA_CRT=${SA_CA_CRT}
EOL
pe

green "Enabling and configuring the K8s auth method in Vault"
pe "vault auth enable kubernetes"
cat << EOL
vault write auth/kubernetes/config
    kubernetes_host="https://$K8S_HOST:8443"
    token_reviewer_jwt="$SA_JWT_TOKEN"
    kubernetes_ca_cert="$SA_CA_CRT"
EOL

vault write auth/kubernetes/config \
    kubernetes_host="https://$K8S_HOST:8443" \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_ca_cert="$SA_CA_CRT"

green "Configuring finance namespace in K8s"
pe "NAMESPACE=finance"
pe "kubectl create namespace ${NAMESPACE}"
pe "kubectl --namespace=${NAMESPACE} create sa ar-app"
pe "kubectl --namespace=${NAMESPACE} create sa ap-app"
# Create the vault namespace at the same time
# vault namespace create ${NAMESPACE}

green "Configuring Vault for the Finance secrets"
pe "vault policy write finance-ar-app-read finance/ar-app-vault-policy.hcl"

cat << EOL
vault write auth/kubernetes/role/finance-ar-app \
    bound_service_account_names=ar-app \
    bound_service_account_namespaces=finance \
    policies=finance-ar-app-read \
    ttl=24h
EOL
pe

vault write auth/kubernetes/role/finance-ar-app \
    bound_service_account_names=ar-app \
    bound_service_account_namespaces=finance \
    policies=finance-ar-app-read \
    ttl=24h

pe "vault policy write finance-ap-app-read finance/ap-app-vault-policy.hcl"

cat << EOL
vault write auth/kubernetes/role/finance-ap-app \
    bound_service_account_names=ap-app \
    bound_service_account_namespaces=finance \
    policies=finance-ap-app-read \
    ttl=24h
EOL
pe

vault write auth/kubernetes/role/finance-ap-app \
    bound_service_account_names=ap-app \
    bound_service_account_namespaces=finance \
    policies=finance-ap-app-read \
    ttl=24h

green "Configuring the IT namespace in K8s"
# Configuring IT namespace
pe "NAMESPACE=it"
pe "kubectl create namespace ${NAMESPACE}"
pe "kubectl --namespace=${NAMESPACE} create sa support"
pe "kubectl --namespace=${NAMESPACE} create sa operations"

green "Configuring Vault for the IT secrets"
pe "vault policy write it-support-read it/support-vault-policy.hcl"

cat << EOL
vault write auth/kubernetes/role/it-support \
    bound_service_account_names=support \
    bound_service_account_namespaces=it \
    policies=it-support-read \
    ttl=24h
EOL
pe

vault write auth/kubernetes/role/it-support \
    bound_service_account_names=support \
    bound_service_account_namespaces=it \
    policies=it-support-read \
    ttl=24h

pe "vault policy write it-operations-read it/operations-vault-policy.hcl"

cat << EOL
vault write auth/kubernetes/role/it-operations \
    bound_service_account_names=operations \
    bound_service_account_namespaces=it \
    policies=it-operations-read \
    ttl=24h
EOL
pe

vault write auth/kubernetes/role/it-operations \
    bound_service_account_names=operations \
    bound_service_account_namespaces=it \
    policies=it-operations-read \
    ttl=24h

green "Putting applications secrets into Vault"
pe "vault kv put secret/it/operations/config \
    ttl='30s' \
    username='operations' \
    password='operations-suP3rsec(et!'"

pe "vault kv put secret/it/support/config \
    ttl='30s' \
    username='support' \
    password='support-suP3rsec(et!'"

pe "vault kv put secret/finance/ar-app/config \
    ttl='30s' \
    username='ar-app' \
    password='ar-app-suP3rsec(et!'"

pe "vault kv put secret/finance/ap-app/config \
    ttl='30s' \
    username='ap-app' \
    password='ap-app-suP3rsec(et!'"

# Inspecting the data vault will use for login
# Mainly to see the secret
pe "kubectl --namespace=${NAMESPACE} get sa support -o yaml"
echo "export SECRET_NAME=\$(kubectl --namespace=${NAMESPACE} get sa support -o jsonpath=\"{.secrets[0]['name']}\")"
export SECRET_NAME=$(kubectl --namespace=${NAMESPACE} get sa support -o jsonpath="{.secrets[0]['name']}")

# To see the secret objects associated with that service account
pe "kubectl --namespace=${NAMESPACE} get secret ${SECRET_NAME} -o yaml"

echo "export SA_JWT_TOKEN=\$(kubectl --namespace=${NAMESPACE} get secret ${SECRET_NAME} -o jsonpath=\"{.data.token}\" | base64 --decode; echo)"
export SA_JWT_TOKEN=$(kubectl --namespace=${NAMESPACE} get secret ${SECRET_NAME} -o jsonpath="{.data.token}" | base64 --decode; echo)


# Create all the config maps for all the different applications
pe "export NAMESPACE=it"
pe "kubectl --namespace=${NAMESPACE} create configmap vault-agent-configs --from-file=configs-k8s/"

pe "export APP=operations"
pe "./template-k8s-pod.yml.sh"
green "Creating application ${APP} in namespace ${NAMESPACE}"
pe "kubectl --namespace=${NAMESPACE} apply -f ${NAMESPACE}/${APP}.yaml"

pe "export FORWARD_PORT=8080"
cat << EOL
In another window, run the following command, 

kubectl --namespace=${NAMESPACE} port-forward pod/vault-agent-${NAMESPACE}-${APP} ${FORWARD_PORT}:80

Then connect to your browser at http://localhost:${FORWARD_PORT}
OR
curl -s http://localhost:${FORWARD_PORT}
EOL
pe


pe "export APP=support"
pe "./template-k8s-pod.yml.sh"
green "Creating application ${APP} in namespace ${NAMESPACE}"
pe "kubectl --namespace=${NAMESPACE} apply -f ${NAMESPACE}/${APP}.yaml"

pe "export FORWARD_PORT=8081"
cat << EOL
In another window, run the following command, 

kubectl --namespace=${NAMESPACE} port-forward pod/vault-agent-${NAMESPACE}-${APP} ${FORWARD_PORT}:80

Then connect to your browser at http://localhost:${FORWARD_PORT}
OR
curl -s http://localhost:${FORWARD_PORT}
EOL
pe


pe "export NAMESPACE=finance"
pe "kubectl --namespace=${NAMESPACE} create configmap vault-agent-configs --from-file=configs-k8s/"

pe "export APP=ar-app"
pe "./template-k8s-pod.yml.sh"
green "Creating application ${APP} in namespace ${NAMESPACE}"
pe "kubectl --namespace=${NAMESPACE} apply -f ${NAMESPACE}/${APP}.yaml"

pe "export FORWARD_PORT=8082"
cat << EOL
In another window, run the following command, 

kubectl --namespace=${NAMESPACE} port-forward pod/vault-agent-${NAMESPACE}-${APP} ${FORWARD_PORT}:80

Then connect to your browser at http://localhost:${FORWARD_PORT}
OR
curl -s http://localhost:${FORWARD_PORT}
EOL
pe



pe "export APP=ap-app"
pe "./template-k8s-pod.yml.sh"
green "Creating application ${APP} in namespace ${NAMESPACE}"
pe "kubectl --namespace=${NAMESPACE} apply -f ${NAMESPACE}/${APP}.yaml"

pe "export FORWARD_PORT=8083"
cat << EOL
In another window, run the following command, 

kubectl --namespace=${NAMESPACE} port-forward pod/vault-agent-${NAMESPACE}-${APP} ${FORWARD_PORT}:80

Then connect to your browser at http://localhost:${FORWARD_PORT}
OR
curl -s http://localhost:${FORWARD_PORT}
EOL
pe

green "Welcome to the wonderful world of using Vault Agent with Kubernetes!"
green "If you're Kubernetes aware, feel free to poke around your systems to see any other behaviors you find interesting"
green "Try things like trying to get secrets from inside one pod from other namespace/service account combinations!"

