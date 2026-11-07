# Lab 6: Kubernetes

Docker runs containers. **Kubernetes** keeps them running: it restarts failures, shares traffic between copies, and updates them without downtime. You say "I want 2 copies" and it makes that stay true. **k3s** is a full Kubernetes that fits on a small VM.

**In your Poultry project:** `infra/helm/poultry` describes the app for k3s. [30-poultry.yaml](../k8s/30-poultry.yaml) is a smaller, hand-written version of that chart, so you can see what it generates.

This lab has its own database, and it never connects to real staging. k3s does change the VM's network rules, so make sure your snapshot exists. Your check at the end confirms real staging still works.

## 1. Start k3s

```bash
~/devops-lab/scripts/stop-all.sh
```

```bash
sudo systemctl start k3s
```

Wait about a minute, then check. `Ready` means it's working:

```bash
kubectl get nodes
```

## 2. Give k3s your image

k3s keeps its images separately from Docker, so import yours:

```bash
docker save poultry-lab:1.0 | sudo k3s ctr images import -
```

## 3. Deploy

Read the files in [k8s/](../k8s), then apply them:

```bash
cd ~/devops-lab && kubectl apply -f k8s/
```

```bash
kubectl -n poultry-lab get pods -w
```

Press Ctrl+C when all three pods show `1/1 Running`. This takes a few minutes, because k3s downloads MySQL first. Then try it:

```bash
curl -s localhost:30080/readyz
```

| Object | Job |
|---|---|
| **Pod** | Runs your container |
| **Deployment** | Keeps the right number of pods running |
| **Service** | Gives them one stable address and shares the traffic |
| **Secret** | Holds the database password |
| **PersistentVolumeClaim** | Keeps MySQL's data when its pod is replaced |
| **Namespace** | Keeps this lab's objects together |

## 4. Watch it heal itself

Open a second SSH window and run:

```bash
kubectl -n poultry-lab get pods -w
```

In the first window, delete the app's pods:

```bash
kubectl -n poultry-lab delete pod -l app=poultry --wait=false
```

Kubernetes creates replacements immediately.

## 5. Scale

```bash
kubectl -n poultry-lab scale deployment poultry --replicas=3
```

```bash
kubectl -n poultry-lab get pods -o wide
```

Then scale back to 2, since this VM has limited memory.

## 6. Update without downtime

Build and import a new release:

```bash
docker build --build-arg RELEASE_SHA=second-release -t poultry-lab:2.0 ~/poultry
```

```bash
docker save poultry-lab:2.0 | sudo k3s ctr images import -
```

In your second window, watch the service during the update:

```bash
while true; do curl -s -m 2 localhost:30080/readyz | grep -o '"release":"[^"]*"' || echo FAILED; sleep 1; done
```

In the first window, start the update:

```bash
kubectl -n poultry-lab set image deployment/poultry web=poultry-lab:2.0
```

The release changes from `first-release` to `second-release`, with no `FAILED` lines.

## 7. Roll back

```bash
kubectl -n poultry-lab rollout undo deployment/poultry
```

```bash
kubectl -n poultry-lab rollout history deployment/poultry
```

## Check

```bash
./scripts/check.sh k8s && ./scripts/check.sh staging
```

## Break it

**A bad release:**

```bash
kubectl -n poultry-lab set image deployment/poultry web=poultry-lab:does-not-exist
```

Now investigate as you would at work:

```bash
kubectl -n poultry-lab get pods
```

```bash
kubectl -n poultry-lab describe pods -l app=poultry | tail -20
```

The old pods keep serving traffic, because `maxUnavailable: 0` stops Kubernetes removing them until new ones are ready. Fix it with `rollout undo`.

**A database outage:**

```bash
kubectl -n poultry-lab scale deployment mysql --replicas=0
```

The app's pods turn `0/1` not ready, but they don't restart. The readiness probe checks the database, and the liveness probe doesn't. Bring MySQL back with `--replicas=1`, and watch the pods recover by themselves. Your data survives on the volume.

These commands are your standard toolkit:

| Command | Use it to |
|---|---|
| `kubectl get pods` | See the state |
| `kubectl describe pod NAME` | See events and why something failed |
| `kubectl logs NAME` | See the app's output |
| `kubectl exec -it NAME -- sh` | Look inside |

## Finish

Remove everything, including the lab's database:

```bash
kubectl delete -f k8s/
```

```bash
./scripts/stop-all.sh
```

## Test yourself

1. What is the difference between a Pod, a Deployment and a Service?
2. What is the difference between a readiness probe and a liveness probe?
3. Why did the bad image cause no outage?
4. Read `infra/helm/poultry/templates/deployment.yaml`. What does the Helm chart add over these plain files?
5. OpenShift is built on Kubernetes. What does it add?
