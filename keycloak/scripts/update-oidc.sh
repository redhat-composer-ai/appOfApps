RETRIES=0

echo "Attempting to get cluster base domain URL"
DOMAIN_URL=$(oc get dns/$DNS_NAME -o jsonpath={.spec.baseDomain})
API_URL="https://api."$DOMAIN_URL":6443"

echo "Using OpenShift API at "$API_URL

echo "Attempting to get cluster app URL from ingress"
APP_URL=$(oc get ingresses.config/$INGRESS_NAME -o jsonpath={.spec.domain})
KEYCLOAK_URL="https://keycloak-"$NAMESPACE"."$APP_URL

echo "Connecting to Keycloak at "$KEYCLOAK_URL
echo "Verifying Keycloak is available"

until $(curl -k --fail "$KEYCLOAK_URL")
do
  if [[ "$RETRIES" -eq 10 ]]; then
    echo "Keycloak unavailable after 10 retries"
    exit 1
  fi
  (( RETRIES++ ))
  echo "Keycloak did not respond.  Retrying after 60 seconds. Attempt "$RETRIES
  sleep 60


done

echo "Getting the oidc secret"

oc extract secret/openshift-oidc-secret --keys=token --to=/tmp $1>/dev/null

oc extract secret/composer-ai-rhbk-initial-admin --to=/tmp $1>/dev/null

CLIENT_SECRET=$(cat /tmp/token)
KEYCLOAK_USER=$(cat /tmp/username)
KEYCLOAK_PASS=$(cat /tmp/password)

echo "Retrieving access token from Keycloak"

access_token=$(curl -k -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'username='$KEYCLOAK_USER \
--data-urlencode 'password='$KEYCLOAK_PASS \
--data-urlencode 'grant_type=password' \
--data-urlencode 'client_id=admin-cli' | jq --raw-output '.access_token')

if [ -z "${access_token}" ]; then
  echo "Access token was not retrieved from keycloak."
  exit 1
fi

jq --arg CLIENT_SECRET $CLIENT_SECRET --arg redirect "[$REDIRECT_URIS]" --arg API_URL $API_URL \
  '(.identityProviders[] | select(.alias == "openshift-v4")) 
   .config.clientSecret |= $CLIENT_SECRET |
   (.identityProviders[] | select(.alias == "openshift-v4")) .config.baseUrl |= $API_URL' \
   /etc/scripts/realm.json > /tmp/updated_realm.json

curl -k -s -X POST "$KEYCLOAK_URL/admin/realms/" \
--header 'Authorization: Bearer '$access_token \
--header 'Content-Type: application/json' \
--data @/tmp/updated_realm.json


echo "Updating service account with redirect URIs"
oc patch serviceaccount openshift-oidc -p '{"metadata":{"annotations": {"serviceaccounts.openshift.io/oauth-redirecturi.first": "'$KEYCLOAK_URL'/realms/openshift-ai/broker/openshift-v4/endpoint"}}}'
 
rm -rf /tmp/*.json /tmp/token /tmp/ADMIN_USERNAME /tmp/ADMIN_PASSWORD
