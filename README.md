# Keycloak Operator Kubernetes resources

A repository containing files to install the Operator without using OLM. The files are stored in individual tags in this repository.

For instructions see: https://www.keycloak.org/operator/installation#_installing_by_using_kubectl_without_operator_lifecycle_manager

## Helm chart

A Helm chart is available in
[`charts/keycloak-operator`](https://github.com/akopyanlabs/keycloak-operator/tree/master/charts/keycloak-operator).
It wraps the manifests from this repository, installs the Keycloak CRDs and runs the operator
**cluster-wide** by default (can be restricted to a set of namespaces with `watchNamespaces`). It
can also create Keycloak instances (`Keycloak` / `KeycloakRealmImport` CRs) as part of the release.

From a checkout of this repository:

```console
helm install keycloak ./charts/keycloak-operator -n keycloak --create-namespace
```

Once CI has published a release, the chart is served from GitHub Pages:

```console
helm repo add akopyanlabs https://akopyanlabs.github.io/keycloak-operator/
helm repo update
helm install keycloak akopyanlabs/keycloak-operator -n keycloak --create-namespace
```

See the
[chart README](https://github.com/akopyanlabs/keycloak-operator/blob/master/charts/keycloak-operator/README.md)
for the full documentation.
