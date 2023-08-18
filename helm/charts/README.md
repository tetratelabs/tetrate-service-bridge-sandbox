# helm charts location placeholder

## How to use helm repo
```bash
# Add Repo
helm repo helm-tsb-sandbox https://tetrateio.github.io/tetrate-service-bridge-sandbox
# Update Repo(s)
helm repo update
#Find the chart to install
helm search repo helm-tsb-sandbox
```

## Helm Repo Details

### Tetrate-Demoapp-Template
Demo helm chart to deploy workspace and group pre-requisits.

Sample `values.yaml`
```yaml
tsb:
  org: tetrate
  tenant: dev
  appNamespace: httpbin
```

```bash
helm install tetrate-demoapp-httpbin helm-tsb-sandbox/tetrate-demoapp-template -f values.yaml
```