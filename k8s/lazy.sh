# Allows you to use an environment variable for k8s namespaces
alias kctl="kubectl --namespace=\${NAMESPACE} "

kubectl create sa vault-auth
kubectl apply -f vault-auth-cluster-role-binding.yml

# Grabbing all the data needed to configure the kubernetes auth method to connect to K8s 
# Assuming the first secret is the one we want to use
export VAULT_SA_SECRET_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[0]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_SECRET_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(minikube ip)

NAMESPACE=finance
kubectl create namespace ${NAMESPACE}
kctl create sa ar-app
kctl create sa ap-app

NAMESPACE=it
kubectl create namespace ${NAMESPACE}
kctl create sa support
kctl create sa operations

# Mainly to see the secret
kctl get sa support -o yaml
export SECRET_NAME=$(kctl get sa support -o jsonpath="{.secrets[0]['name']}")

# To see the secret objects associated with that service account
kctl get secret ${SECRET_NAME} -o yaml
export SA_JWT_TOKEN=$(kctl get secret ${SECRET_NAME} -o jsonpath="{.data.token}" | base64 --decode; echo)


vault auth enable kubernetes

vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="https://$K8S_HOST:8443" \
    kubernetes_ca_cert="$SA_CA_CRT"

# Testing the container run 
kctl run tmp --rm -i --tty \
  --serviceaccount=support \
  --env="K8S_HOST=${K8S_HOST}" \
  --env="VAULT_ADDR=${VAULT_ADDR}" \
  --image grovemountain/hashicorp_agent_tools:latest

curl -s $VAULT_ADDR/v1/sys/health | jq







