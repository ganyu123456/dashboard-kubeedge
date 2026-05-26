# KubeEdge Dashboard

## Introduction
KubeEdge dashboard provides a graphical user interface (GUI) for managing and monitoring your KubeEdge clusters. It allows users to manage edge applications running in the cluster and troubleshoot them.

This project is currently in development, and we will iterate it continuously. We welcome any feedback and contributions.

## Contact
If you have any questions, feel free to reach out to us in the following ways:
* [Slack #dashboard](https://kubeedge.io/docs/community/slack/)

## Prepare environment

The KubeEdge dashboard consists of two modules: backend and frontend. The backend module is responsible for providing APIs to the frontend, while the frontend module is responsible for rendering the user interface.

For backend module, golang is needed.

For frontend module, nodejs, npm/yarn/pnpm is needed, pnpm is recommended.

## Install packages

### Backend

To install the backend dependencies, you need to have Go installed. You can use the following command to install the dependencies:

```bash
cd module
go mod download
```

### Frontend

To install the frontend dependencies, you can use npm, yarn, or pnpm. Choose one of the following commands based on your preference:

```bash with npm
cd module/web
npm install
```

```bash with yarn
cd module/web
yarn install
```

or

```bash with pnpm
cd module/web
pnpm install
```

### Start project

### Backend

You can start the backend server by running the following command:

```bash
cd module/api
go run main.go --apiserver-host=https://192.168.33.129:6443
```

If your API server is running with self-signed certificate, you can set `--apiserver-skip-tls-verify true` option to ignore the certificate verification.

### Frontend

```bash with npm
cd module/web
npm run build
API_SERVER={api module address} npm run start
Example: API_SERVER=http://127.0.0.1:8080 npm run dev
```
or

```bash with yarn
cd module/web
yarn build
API_SERVER={api module address} yarn start
Example: API_SERVER=http://127.0.0.1:8080 yarn dev
```
or

```bash with pnpm
cd module/web
pnpm run build
API_SERVER={api module address} pnpm run start
Example: API_SERVER=http://127.0.0.1:8080 pnpm run dev
```

### Login with token

```bash
kubectl create serviceaccount curl-user -n kube-system
kubectl create clusterrolebinding curl-user-binding --clusterrole=cluster-admin --serviceaccount=kube-system:curl-user -n kube-system

# For Kubernetes 1.23 and earlier:
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep curl-user | awk '{print $1}')
# For Kubernetes 1.24 and later:
kubectl create token curl-user -n kube-system
```

## Deploy with Helm

A Helm Chart is provided under [`charts/kubeedge-dashboard`](./charts/kubeedge-dashboard) for quick deployment to any Kubernetes / KubeEdge cluster. The CI workflow publishes both the multi-arch container image and the Helm Chart to Harbor on every `v*` tag, and also attaches offline artifacts to the corresponding GitHub Release.

### Prerequisites

- Kubernetes >= 1.20 (KubeEdge cluster supported)
- Helm >= 3.8 (OCI registry support required)
- Network access to `harbor.zkjgy.online`, or an offline image / chart bundle

### Option 1: Online install from Harbor (OCI)

```bash
helm install kubeedge-dashboard \
  oci://harbor.zkjgy.online/charts/kubeedge-dashboard \
  --version <chart-version> \
  --create-namespace -n kubeedge-dashboard
```

> Replace `<chart-version>` with the version published in the GitHub Release (e.g. `0.1.0`). Omit `--version` to install the latest.

### Option 2: Install from local chart source

```bash
helm install kubeedge-dashboard ./charts/kubeedge-dashboard \
  --create-namespace -n kubeedge-dashboard
```

### Option 3: Offline install (air-gapped server)

Download the assets from the corresponding [GitHub Release](../../releases):

- `kubeedge-dashboard-amd64.tar.gz` / `kubeedge-dashboard-arm64.tar.gz` — offline container image
- `kubeedge-dashboard-<version>.tgz` — offline Helm chart

Then on the offline server:

```bash
# 1. Load image into the local container runtime
#    Docker
gunzip -c kubeedge-dashboard-amd64.tar.gz | docker load
#    containerd / k3s
gunzip -c kubeedge-dashboard-amd64.tar.gz | ctr -n=k8s.io images import -
# gunzip -c kubeedge-dashboard-amd64.tar.gz | k3s ctr images import -

# 2. Install the chart from the local tgz
helm install kubeedge-dashboard kubeedge-dashboard-<version>.tgz \
  --create-namespace -n kubeedge-dashboard
```

> If your cluster nodes pull images from a private registry, push the loaded image to that registry first and override `--set image.repository=<your-registry>/kubeedge-dashboard`.

### Customizing values

Common values you may want to override (see [`charts/kubeedge-dashboard/values.yaml`](./charts/kubeedge-dashboard/values.yaml) for the full list):

| Key | Default | Description |
|------|---------|-------------|
| `image.repository` | `harbor.zkjgy.online/library/kubeedge-dashboard` | Container image repository |
| `image.tag` | `latest` | Image tag |
| `webService.type` | `NodePort` | Web service type (`NodePort` / `ClusterIP` / `LoadBalancer`) |
| `webService.nodePort` | `30080` | NodePort for the web UI when `type=NodePort` |
| `config.apiServerHost` | `https://kubernetes.default.svc:6443` | Kubernetes API server address used by the backend |
| `config.apiServerSkipTlsVerify` | `"true"` | Skip TLS verification for the API server |
| `ingress.enabled` | `false` | Enable Ingress |
| `ingress.host` | `dashboard.kubeedge.local` | Ingress hostname |

Example with overrides:

```bash
helm install kubeedge-dashboard ./charts/kubeedge-dashboard \
  --create-namespace -n kubeedge-dashboard \
  --set image.tag=v1.0.0 \
  --set webService.nodePort=30088 \
  --set ingress.enabled=true \
  --set ingress.host=dashboard.example.com
```

### Access the Dashboard

After the pods are ready:

```bash
kubectl -n kubeedge-dashboard get pods
kubectl -n kubeedge-dashboard get svc
```

Open `http://<node-ip>:30080` (or your configured `nodePort` / Ingress host) in a browser, then log in with a ServiceAccount token (see [Login with token](#login-with-token) above).

### Upgrade / Uninstall

```bash
# Upgrade
helm upgrade kubeedge-dashboard oci://harbor.zkjgy.online/charts/kubeedge-dashboard \
  --version <new-chart-version> -n kubeedge-dashboard

# Uninstall
helm uninstall kubeedge-dashboard -n kubeedge-dashboard
kubectl delete ns kubeedge-dashboard
```

## Contributing
If you're interested in being a contributor and want to get involved in developing the KubeEdge code, please see [CONTRIBUTING](./CONTRIBUTING.md) for details on submitting patches and the contribution workflow.

## License
KubeEdge is under Apache 2.0 license. See the [LICENSE](LICENSE) file for details.
