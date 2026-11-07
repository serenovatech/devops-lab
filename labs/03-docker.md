# Lab 3: Docker and Compose

An **image** is a packaged app with everything it needs. A **container** is a running copy of an image. **Compose** starts several containers together from one file.

Your real app runs directly on the VM with systemd. Here you'll run a separate copy in containers, so you can compare the two.

Run everything from `~/devops-lab`:

```bash
cd ~/devops-lab && git -C ~/poultry pull
```

## 1. Read your Dockerfile

Open `~/poultry/Dockerfile`. Find these and work out why each one is there:

- Two `FROM` lines. The first stage builds, and the second is what ships.
- `USER node`, so the app doesn't run as root.
- `HEALTHCHECK`, so Docker can see whether the app is healthy.
- The step that removes npm. Your lab report explains why: Trivy found 10 HIGH vulnerabilities in it.

## 2. Build the image

This takes several minutes the first time:

```bash
docker build --build-arg RELEASE_SHA=first-release -t poultry-lab:1.0 ~/poultry
```

```bash
docker images poultry-lab
```

Run the same build again. It finishes in seconds, because Docker reuses cached layers.

## 3. Run the lab copy

Read [compose.yaml](../compose.yaml), then start it:

```bash
docker compose up -d --build
```

```bash
docker compose ps
```

Wait until `app` shows `healthy`, then compare your two apps:

```bash
curl -s localhost:3200/readyz; echo; curl -s localhost:8080/readyz
```

Open `http://VM_IP:3200` in your browser. It's a separate app with an empty database.

| Your real app | The lab copy |
|---|---|
| Started by `systemctl` | Started by `docker compose` |
| Logs with `journalctl -u serenova` | Logs with `docker compose logs app` |
| Files in `/opt/serenova/releases` | Files inside an image |
| MySQL service on the VM | MySQL in a container |

## 4. Look inside

| Command | What it does |
|---|---|
| `docker compose logs --tail 20 app` | Shows the app's output |
| `docker compose exec app sh` | Opens a shell inside. Run `whoami` and `ls`, then `exit` |
| `docker stats --no-stream` | Shows memory and CPU |
| `docker inspect poultry-lab-app-1` | Shows every setting |

Inside the shell, try `npm --version`. It fails, because the image has no npm.

## 5. Volumes keep data

Finish the first-run setup in your browser, so that the database has something in it. Then replace the containers:

```bash
docker compose down
```

```bash
docker compose up -d
```

Your data is still there, because it's in a **volume**, outside the containers. `docker compose down -v` would delete the volume too.

## 6. Scan the image

Your VM already has Trivy, the scanner your Container workflow uses:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.70.0 image --severity HIGH,CRITICAL --ignore-unfixed poultry-lab:1.0
```

## Check

```bash
./scripts/check.sh docker && ./scripts/check.sh staging
```

## Break it

1. **Database outage:** run `docker compose stop mysql`. Then `curl -s localhost:3200/readyz` returns `503`, but `/healthz` stays OK and the app doesn't restart. That's your MySQL drill, with no risk to real staging. Bring it back with `docker compose start mysql`.
2. **Port clash:** change the lab copy's port from `3200` to `8080` in `compose.yaml`, and run `docker compose up -d`. Read the error, then change it back. Docker can't take a port that nginx already holds.
3. **Memory limit:** run `docker stats --no-stream`, and find the 384 MB limit from `compose.yaml`.

Leave the image in place. Later labs use it. When you're done:

```bash
./scripts/stop-all.sh
```

## Test yourself

1. What is the difference between an image and a container?
2. Why does the Dockerfile have two stages?
3. What are the pros and cons of running your real app in containers instead of with systemd?
4. Podman runs the same images without a background daemon. Why might that be more secure?
