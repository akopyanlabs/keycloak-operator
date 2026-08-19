# keycloak-operator Helm Chart

Deploys the [Keycloak Operator](https://www.keycloak.org/operator) from the
official upstream manifests, installs the Keycloak CRDs and can optionally
manage Keycloak instances through `Keycloak` / `KeycloakRealmImport` custom
resources.

The operator runs **cluster-wide by default**: it watches `Keycloak`,
`KeycloakRealmImport`, `KeycloakOIDCClient` and `KeycloakSAMLClient` CRs in all
namespaces and uses ClusterRoleBindings. The scope can be narrowed to a fixed
list of namespaces via `watchNamespaces` (RoleBindings are then created in each
of them).

## Prerequisites

- Kubernetes (check the versions supported by the given Keycloak release in the
  [Keycloak supported platforms](https://www.keycloak.org/docs/latest/server_installation/#supported-operating-systems) list)
- Helm 3.8+
- Optional: Prometheus Operator, if `serviceMonitor.enabled=true`

## Installing the Chart

```console
helm install keycloak ./charts/keycloak-operator \
  --namespace keycloak --create-namespace
```

The command deploys the operator to the `keycloak` namespace. See
`helm install --help` for all options.

> **CRD lifecycle:** the CRDs (`keycloaks`, `keycloakrealmimports`,
> `keycloakoidcclients`, `keycloaksamlclients`) ship as regular chart
> resources: `helm install` and `helm upgrade` create and update them
> automatically. They carry `helm.sh/resource-policy: keep`, so
> `helm uninstall` leaves them — and the Keycloak resources — in place.
> See [Uninstalling](#uninstalling) below.

## Installing a Keycloak instance

Either let the chart create the CR (see `ci/keycloak-instance.yaml`):

```console
helm install keycloak ./charts/keycloak-operator \
  --namespace keycloak --create-namespace \
  -f ci/keycloak-instance.yaml
```

or apply any `Keycloak` CR yourself — the operator watches the whole cluster by
default:

```yaml
apiVersion: k8s.keycloak.org/v2beta1
kind: Keycloak
metadata:
  name: keycloak
  namespace: keycloak
spec:
  instances: 1
  ingress:
    enabled: true
```

### Bootstrap admin

Keycloak 26+ refuses to start without bootstrap admin credentials. When the
chart manages the `Keycloak` CR and you have not set `spec.bootstrapAdmin`
yourself, it:

1. creates a Secret `<keycloak CR name>-bootstrap-admin` with the keys
   `username` / `password` taken verbatim from `keycloak.bootstrapAdmin.username`
   / `.password` (`keycloak.bootstrapAdmin.create`, default `true`) — the
   credentials are **mandatory** in this mode and enforced by
   `values.schema.json`; there is no generated default, and
2. injects `spec.bootstrapAdmin.user.secret` referencing that Secret.

To use a Secret you manage yourself (e.g. from Vault / External Secrets):

```console
helm install keycloak ./charts/keycloak-operator -n keycloak \
  --set keycloak.enabled=true \
  --set keycloak.bootstrapAdmin.existingSecret=my-corp-keycloak-admin
```

The Secret name used for the injection is printed in the post-install NOTES
together with a command to read the generated password.

## Watch scopes

| `watchNamespaces`    | Behaviour                                                                                     |
| -------------------- | --------------------------------------------------------------------------------------------- |
| `"*"` (default)      | Cluster-wide. ClusterRoleBindings, `JOSDK_ALL_NAMESPACES`.                                     |
| `["ns-a", "ns-b"]`   | Watches the listed namespaces. RoleBindings in each (plus the release namespace).              |
| `""`                 | Watches only the release namespace (`JOSDK_WATCH_CURRENT`).                                    |

## Upgrading

```console
helm upgrade keycloak ./charts/keycloak-operator --namespace keycloak
```

The CRDs are part of the chart templates and are updated by the same
`helm upgrade` — no manual `kubectl apply` is needed.

## Uninstalling

```console
helm uninstall keycloak --namespace keycloak
```

This removes the operator, its RBAC and the CRs created by the chart, but keeps
the cluster-scoped CRDs (`helm.sh/resource-policy: keep`) and the Keycloak
resources managed by them. To remove the CRDs too (⚠️ this cascades to all
Keycloak deployments managed by CRs):

```console
kubectl delete crd keycloaks.k8s.keycloak.org keycloakrealmimports.k8s.keycloak.org \
  keycloakoidcclients.k8s.keycloak.org keycloaksamlclients.k8s.keycloak.org
```

## Values

| Key | Default | Description |
|-----|---------|-------------|
| `replicaCount` | `1` | Operator replicas. Upstream has no leader election — keep `1`. |
| `image.registry` | `quay.io` | Operator image registry. |
| `image.repository` | `keycloak/keycloak-operator` | Operator image repository. |
| `image.tag` | `""` (chart `appVersion`) | Operator image tag. |
| `image.digest` | `""` | Operator image digest (overrides `tag`). |
| `image.pullPolicy` | `Always` | Operator image pull policy. |
| `imagePullSecrets` | `[]` | Global image pull secrets. |
| `nameOverride` | `""` | Partially override resource names. |
| `fullnameOverride` | `""` | Fully override generated resource names. |
| `watchNamespaces` | `"*"` | `"*"` cluster-wide, list of namespaces, or `""` for the release namespace only. |
| `keycloakImage.registry` | `quay.io` | Keycloak image the operator deploys for instances (`RELATED_IMAGE_KEYCLOAK`). |
| `keycloakImage.repository` | `keycloak/keycloak` | Keycloak image repository. |
| `keycloakImage.tag` | `""` (chart `appVersion`) | Keycloak image tag. |
| `keycloakImage.digest` | `""` | Keycloak image digest (overrides `tag`). |
| `serviceAccount.create` | `true` | Create the operator ServiceAccount. |
| `serviceAccount.name` | `""` | ServiceAccount name (defaults to the fullname). |
| `serviceAccount.annotations` | `{}` | Extra ServiceAccount annotations. |
| `serviceAccount.labels` | `{}` | Extra ServiceAccount labels. |
| `rbac.create` | `true` | Create ClusterRoles and (Cluster)RoleBindings. |
| `service.type` | `ClusterIP` | Operator Service type. |
| `service.ports` | see `values.yaml` | Operator Service ports (`80` → `http`). |
| `serviceMonitor.enabled` | `false` | Create a ServiceMonitor for `/q/metrics` (needs Prometheus Operator). |
| `serviceMonitor.namespace` | `""` | Namespace for the ServiceMonitor. |
| `serviceMonitor.interval` | `30s` | Scrape interval. |
| `serviceMonitor.path` | `/q/metrics` | Metrics path. |
| `serviceMonitor.labels` | `{}` | Labels for Prometheus discovery (e.g. `release: prometheus`). |
| `serviceMonitor.relabelings` | `[]` | Endpoint relabelings. |
| `resources` | upstream defaults | Operator container resources (`300m`/`450Mi` requests, `700m`/`450Mi` limits). |
| `podAnnotations` | `{}` | Extra Pod annotations. |
| `podLabels` | `{}` | Extra Pod labels. |
| `podSecurityContext` | `runAsNonRoot: true`, `seccompProfile: RuntimeDefault` | Pod security context. |
| `securityContext` | `allowPrivilegeEscalation: false`, `capabilities: [ALL]` drop | Container security context. |
| `nodeSelector` | `{}` | Node selector. |
| `tolerations` | `[]` | Tolerations. |
| `affinity` | `{}` | Affinity rules. |
| `topologySpreadConstraints` | `[]` | Topology spread constraints. |
| `priorityClassName` | `""` | Pod priority class. |
| `extraEnv` | `[]` | Extra environment variables (e.g. `KC_TRUST_CERTS`). |
| `extraEnvFrom` | `[]` | Extra `envFrom` sources. |
| `extraVolumes` | `[]` | Extra volumes (e.g. custom CA bundle). |
| `extraVolumeMounts` | `[]` | Extra container volume mounts. |
| `livenessProbe` / `readinessProbe` / `startupProbe` | upstream defaults | Container probes (`/q/health/*` on port `http`); set to `null` to remove. |
| `keycloak.enabled` | `false` | Create a `Keycloak` CR. |
| `keycloak.nameOverride` | `""` (release name) | Name of the `Keycloak` CR. |
| `keycloak.bootstrapAdmin.existingSecret` | `""` | Use an existing Secret (`username`/`password` keys) instead of creating one; injected into `spec.bootstrapAdmin.user.secret`. |
| `keycloak.bootstrapAdmin.create` | `true` | Create the bootstrap admin Secret (ignored when `existingSecret` is set or `spec.bootstrapAdmin` is configured manually). |
| `keycloak.bootstrapAdmin.secretName` | `""` (`<CR name>-bootstrap-admin`) | Name of the created Secret. |
| `keycloak.bootstrapAdmin.username` | `admin` | Bootstrap admin username (required when the chart creates the Secret). |
| `keycloak.bootstrapAdmin.password` | `""` | Bootstrap admin password — must be set when the chart creates the Secret (enforced by `values.schema.json`). |
| `keycloak.bootstrapAdmin.secretAnnotations` | `{}` | Extra annotations for the created Secret. |
| `keycloak.labels` / `keycloak.annotations` | `{}` | Extra CR metadata. |
| `keycloak.spec` | `{}` | `spec` of the `Keycloak` CR ([reference](https://www.keycloak.org/operator/custom-resources)). |
| `realmImports` | `[]` | List of `KeycloakRealmImport` CRs (`name`, `keycloakCRName`, `realm`, `resources`, `labels`). |

Specify each parameter with `--set key=value[,key=value]` or `-f values.yaml`.

## CI values

The `ci/` directory holds per-mode values files used by the CI workflows
(lint + template) and doubles as ready-to-use examples:

- [`ci/keycloak-instance.yaml`](ci/keycloak-instance.yaml) — cluster-wide operator + production-like instance + realm import
- [`ci/dev-instance.yaml`](ci/dev-instance.yaml) — dev instance with plain HTTP and relaxed hostname settings
- [`ci/namespaced.yaml`](ci/namespaced.yaml) — restrict the operator to a list of namespaces

## License

Apache-2.0 (same as [Keycloak](https://github.com/keycloak/keycloak)).
