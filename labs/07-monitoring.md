# Lab 7: Prometheus and Grafana

Your app publishes numbers at `/metrics`. **Prometheus** collects and stores them every 15 seconds. **Grafana** draws them as dashboards.

This lab watches your **real staging app**, but only reads its metrics, so it's safe.

## 1. Find out why monitoring is down

Your old Prometheus and Grafana stopped at the last reboot and never came back. Find out why:

```bash
docker inspect obs-prometheus-1 --format 'restart={{.HostConfig.RestartPolicy.Name}} stopped={{.State.FinishedAt}}'
```

`restart=no` means Docker won't start it again after a reboot. Lab 3's lesson applies here too: a setting created by hand, in `/root/obs`, is easy to get wrong and hard to review.

## 2. Start the new stack

Leave the old containers stopped, because they use the same ports.

Read [monitoring/compose.yaml](../monitoring/compose.yaml), and find `restart: unless-stopped`. It's in Git now, so it can be reviewed and rebuilt:

```bash
cd ~/devops-lab && git -C ~/poultry pull && docker compose up -d
```

```bash
docker compose -f monitoring/compose.yaml up -d
```

The first command starts the lab copy, so you have something safe to break.

## 3. Query Prometheus

See what Prometheus reads:

```bash
curl -s 127.0.0.1:9100/metrics | grep -E '^pfm_(ready|app_info)'
```

Open `http://VM_IP:9090`, then choose **Status → Target health**. `poultry-staging` and `poultry-lab` should both be `UP`.

Choose **Query**, and try these one at a time:

| Query | What it means |
|---|---|
| `up` | 1 if the scrape worked, 0 if not |
| `pfm_ready` | 1 if the app can use its database |
| `pfm_http_requests_total` | Total requests. Only ever goes up |
| `sum by (job) (rate(pfm_http_requests_total[1m]))` | Requests per second, per app |
| `histogram_quantile(0.95, sum by (le) (rate(pfm_http_request_duration_seconds_bucket[5m])))` | The time 95% of requests finish within |

A **counter** only goes up, so you nearly always wrap it in `rate()`. A **gauge**, like `pfm_ready`, can go up and down.

## 4. Create some traffic

Leave this running in a second window. It only sends requests to the lab copy:

```bash
while true; do curl -s localhost:3200/ > /dev/null; curl -s localhost:3200/readyz > /dev/null; sleep 0.5; done
```

## 5. Open the dashboard

Open `http://VM_IP:3001`, log in with `admin` / `admin`, and skip the password change. Find your dashboard in the **Poultry Farm Manager** folder.

It comes from a file in your Poultry repository, `infra/helm/poultry/files/dashboards`. Dashboards in Git can be reviewed and rebuilt, unlike ones clicked together by hand.

Add a panel of your own showing memory in MB, using `process_resident_memory_bytes / 1024 / 1024`.

## Check

```bash
./scripts/check.sh monitoring && ./scripts/check.sh staging
```

## Break it

1. **Lab database down:** run `docker compose stop mysql`. `pfm_ready{job="poultry-lab"}` turns to 0 while real staging stays at 1. Start it again with `docker compose start mysql`.
2. **Find a hidden problem:** query `max(pfm_ready)` during that outage. It still says 1, because real staging is fine. Your Poultry `PfmNotReady` rule uses `max()`, and that works when there's one app. It hides this outage when Prometheus watches two. This is why [alerts-lab.yml](../monitoring/alerts-lab.yml) looks at each app separately.
3. **A reboot test (⚠ REAL STAGING):** your apps go offline for about a minute. Run `sudo reboot`, log back in, and check that Prometheus came back this time. Remember: the runners may not.

Leave the stack running if you're moving on to lab 8 or 9 soon.

## Test yourself

1. Prometheus pulls metrics from apps. What's the advantage over apps pushing them?
2. Why use `rate()` rather than the raw counter?
3. Why does your Poultry app serve metrics on a separate port from its website?
4. Your `alerts.yml` has a memory alert at 900 MB. What is the catch if you run the app with the Helm chart's 768 Mi limit?
5. How do Zabbix and Nagios differ from Prometheus in how they check things?
