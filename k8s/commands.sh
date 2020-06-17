echo "Start Vault from the scripts directory"
echo "../scripts/0_launch_vault.sh"
echo "Unseal vault with:"
echo "../scripts/1_init_unseal_vault.sh"

. ../scripts/env.sh
. ../scripts/root_token

# Allows you to use an environment variable for k8s namespaces
alias kctl="kubectl --namespace=\${NAMESPACE} "

# This is the service account used for verifying JWT tokens coming from K8s ppod requests via Vault
kubectl create sa vault-auth
kubectl apply -f vault-auth-cluster-role-binding.yml

# Grabbing all the data needed to configure the kubernetes auth method to connect to K8s 
# Assuming the first secret is the one we want to use
export VAULT_SA_SECRET_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[0]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_SECRET_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(minikube ip)

vault auth enable kubernetes
vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="https://$K8S_HOST:8443" \
    kubernetes_ca_cert="$SA_CA_CRT"

# Configuring finance namespace
NAMESPACE=finance
kubectl create namespace ${NAMESPACE}
kctl create sa ar-app
kctl create sa ap-app
# Create the vault namespace at the same time
# vault namespace create ${NAMESPACE}

vault policy write finance-ar-app-read finance/ar-app-vault-policy.hcl

vault write auth/kubernetes/role/finance-ar-app \
    bound_service_account_names=ar-app \
    bound_service_account_namespaces=finance \
    policies=finance-ar-app-read \
    ttl=24h

vault policy write finance-ap-app-read finance/ap-app-vault-policy.hcl

vault write auth/kubernetes/role/finance-ap-app \
    bound_service_account_names=ap-app \
    bound_service_account_namespaces=finance \
    policies=finance-ap-app-read \
    ttl=24h


# Configuring IT namespace
NAMESPACE=it
kubectl create namespace ${NAMESPACE}
kctl create sa support
kctl create sa operations
# Create the vault namespace at the same time
# vault namespace create ${NAMESPACE}

# VAULT_NAMESPACE=${NAMESPACE}
vault policy write it-support-read it/support-vault-policy.hcl

vault write auth/kubernetes/role/it-support \
    bound_service_account_names=support \
    bound_service_account_namespaces=it \
    policies=it-support-read \
    ttl=24h

vault policy write it-operations-read it/operations-vault-policy.hcl

vault write auth/kubernetes/role/it-operations \
    bound_service_account_names=operations \
    bound_service_account_namespaces=it \
    policies=it-operations-read \
    ttl=24h

vault kv put secret/it/operations/config \
    ttl='30s' \
    username='operations' \
    password='operations-suP3rsec(et!'

vault kv put secret/it/support/config \
    ttl='30s' \
    username='support' \
    password='support-suP3rsec(et!'

vault kv put secret/finance/ar-app/config \
    ttl='30s' \
    username='ar-app' \
    password='ar-app-suP3rsec(et!'

vault kv put secret/finance/ap-app/config \
    ttl='30s' \
    username='ap-app' \
    password='ap-app-suP3rsec(et!'

# Inspecting the data vault will use for login
# Mainly to see the secret
kctl get sa support -o yaml
export SECRET_NAME=$(kctl get sa support -o jsonpath="{.secrets[0]['name']}")

# To see the secret objects associated with that service account
kctl get secret ${SECRET_NAME} -o yaml
export SA_JWT_TOKEN=$(kctl get secret ${SECRET_NAME} -o jsonpath="{.data.token}" | base64 --decode; echo)


# Create all the config maps for all the different applications
export NAMESPACE=it
kctl create configmap vault-agent-configs --from-file=configs-k8s/

export APP=operations
./template-k8s-pod.yml.sh
kctl apply -f ${NAMESPACE}/${APP}.yaml
kctl port-forward pod/vault-agent-${NAMESPACE}-${APP} 8080:80

export APP=support
./template-k8s-pod.yml.sh
kctl apply -f ${NAMESPACE}/${APP}.yaml

export NAMESPACE=finance
kctl create configmap vault-agent-configs --from-file=configs-k8s/

export APP=ar-app
./template-k8s-pod.yml.sh
kctl apply -f ${NAMESPACE}/${APP}.yaml

export APP=ap-app
./template-k8s-pod.yml.sh
kctl apply -f ${NAMESPACE}/${APP}.yaml


# Testing the container run 
#kctl run tmp --rm -i --tty \
#  --serviceaccount=support \
#  --env="K8S_HOST=${K8S_HOST}" \
#  --env="VAULT_ADDR=${VAULT_ADDR}" \
#  --image grovemountain/hashicorp_agent_tools:latest \
#  curl -s $VAULT_ADDR/v1/sys/health | jq


# Placing the vault auth method directly in the namespace as opposed to the root
# NAMESPACE=it
### MAY NOT USE THIS ###
# Find the accessor for the root namespace kubernetes auth method
# This will be used to setup external/internal group linkages
#vault auth list -format=json | jq -r '.["kubernetes/"].accessor' > accessor.txt
#
#vault write -format=json identity/group \
#  name="it_admin_root" \
#  type="external" \
#  | jq -r ".data.id" > it_admin_group_id.txt
#
#vault write -format=json identity/group \
#  name="finance_admin_root" \
#  type="external" \
#  | jq -r ".data.id" > finance_admin_group_id.txt
#
#vault write -format=json identity/group \
#  name="it_operations_read_root" \
#  type="external" \
#  | jq -r ".data.id" > it_operations_group_id.txt
#
#vault write -format=json identity/group \
#  name="it_support_read_root" \
#  type="external" \
#  | jq -r ".data.id" > it_support_group_id.txt
#
#vault write -format=json identity/group \
#  name="it_admin_root" \
#  type="external" \
#  | jq -r ".data.id" > it_admin_group_id.txt
#
#
#vault write -format=json identity/group \
#  name="finance_admin_root" \
#  type="external" \
#  | jq -r ".data.id" > finance_admin_group_id.txt
