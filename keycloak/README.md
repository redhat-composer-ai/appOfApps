# Keycloak

This template installs an opinionated Keycloak Instance, Route, Postgres database, and oidc client to connect Keycloak to OpenShift's Oidc server. The purpose of this is to allow users of Composer AI to login with their OpenShift credentials.


## Keycloak Instance

This Keycloak instance is setup in an insecure fashion and fronted by an edge terminated Route, meaning only external connections are encrypted.  This is enabled by the following combination of settings:

```
  hostname:
    hostname: ''
    strict: false
  http:
    httpEnabled: true
  proxy:
    headers: xforwarded
```

This is sufficient for demo purposes, but should be replaced with a more secure configuration in real environments. See [Disabling required options](https://www.keycloak.org/operator/advanced-configuration#_disabling_required_options) and [Configure the reverse proxy headers](https://www.keycloak.org/server/reverseproxy#_configure_the_reverse_proxy_headers) for details.

## Postgres Instance

This simple postgres instance pulls credentials from a secret and uses a volumeClaimTemplate to provision volumes. This could be replaced with any postgres instance or cluster required by users.  

Based off of the StatefulSet at [Basic Deployment](https://www.keycloak.org/operator/basic-deployment#_preparing_for_deployment)

## OIDC Client

This setup uses a ServiceAccount as a basic OIDC client.  This exposes a clientId and token that can be used with OpenShift's basic OIDC capabilities.  See [Service accounts as OAuth clients](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/authentication_and_authorization/using-service-accounts-as-oauth-client#service-accounts-as-oauth-clients_using-service-accounts-as-oauth-client) for details.

The Roles and RoleBindings support the "update job".  This Job runs as a PostSync hook for ArgoCD and has two purposes.  

1. Uses the Keycloak API to apply the realm.json file, creating the default "openshift-ai" realm.  If this realm already exists, this call will fail, but not cause an error for the script.
2. Patch the oidc ServiceAccount with a correct oauth redirect uri for Keycloak.  

Note that this job looks at the default ingress and the dns for the cluster to dynamically grab the cluster names.  If this is incorrect for the cluster, the Job can be updated with names for other ingress controllers or dns entries.

## Troubleshooting

Q. I have random errors when logging into the application
A. Check that all the OAuth components have the correct configuration.  If using a different namespace, the "clientId" for OpenShift OIDC changes and must be updated in the realm.json. The RoleBindings must also be updated for the oidc client.

Q. Keycloak is failing to load over https and has cross site errors in the developer console.
A. Make sure that the "proxy" headers are correctly set as forwarded on the Keycloak CR.  