# Lab 8: Logging with Fluent Bit and Loki

Metrics tell you **that** something is wrong. Logs tell you **why**. With several services, you need logs collected in one searchable place.

- **Fluent Bit** collects logs and forwards them. It's the lightweight sibling of Fluentd.
- **Loki** stores them.
- **Grafana** searches them.

The ELK Stack has the same three roles: Logstash collects, Elasticsearch stores and Kibana searches.

This lab reads your **real staging logs** without changing them, so it's safe.

## 1. See where the logs live now

Your real app logs to the systemd journal, and nginx logs to files:

```bash
journalctl -u serenova -n 10 --no-pager
```

```bash
tail -n 5 /var/log/nginx/access.log
```

This works on one server. It stops working when you have many servers, or need to search across them.

## 2. Start the stack

```bash
cd ~/devops-lab && docker compose -f monitoring/compose.yaml --profile logging up -d
```

Read [fluent-bit.conf](../logging/fluent-bit.conf). It reads the journal and nginx's logs, and sends each to Loki under its own label. Loki takes about a minute to become ready.

Fluent Bit may log `timestamp too old` once. It's harmless: Loki's default setting refuses lines older than 7 days.

## 3. Create some logs

Open `http://VM_IP:8080` in your browser and click around, then run:

```bash
for i in 1 2 3 4 5 6 7 8 9 10; do curl -s localhost:8080/healthz > /dev/null; curl -s -o /dev/null localhost:8080/api/does-not-exist; done
```

## 4. Search in Grafana

Open `http://VM_IP:3001`, then **Explore**, and choose **Loki** at the top. Switch to **Code** mode, and set the time range to the **Last 7 days**, because your app writes few lines. Run these queries:

| Query | What it finds |
|---|---|
| `{job="nginx"}` | Every request through nginx |
| `{job="serenova"}` | Your app's own log lines |
| `{job="nginx"} \|= "does-not-exist"` | Lines containing that text |
| `{job="nginx"} \|~ "\" (4\|5)[0-9][0-9] "` | Requests that returned a 4xx or 5xx status |
| `sum(count_over_time({job="nginx"}[5m]))` | The number of requests in 5 minutes |

The last query turns logs into a number. That's useful, but a real metric is cheaper when you already know what to count.

## Check

```bash
./scripts/check.sh logging && ./scripts/check.sh staging
```

## A real problem these logs exposed

When we tested this lab, nginx's `access.log` was empty, even though requests were arriving. Log rotation had renamed the file to `access.log.1` at midnight, and nginx kept writing to the renamed file. Check yours:

```bash
ls -l /var/log/nginx/access.log /var/log/nginx/access.log.1
```

If `access.log` stays at 0 bytes while the site is in use, **⚠ REAL STAGING** this harmless command tells nginx to reopen its log files:

```bash
sudo nginx -s reopen
```

To learn why it happened, read `/etc/logrotate.d/nginx` and run `systemctl status logrotate`. This is why [fluent-bit.conf](../logging/fluent-bit.conf) reads `access.log*`, not just one file.

## Break it

1. **Collector outage:** run `docker compose -f monitoring/compose.yaml --profile logging stop fluent-bit`, and make some requests. Your app keeps working, because collecting logs is separate from serving users. Start it again, and see which lines arrive.
2. **A daily backup:** your lab report's first bug was found by reading logs: a successful backup was logged as failed. Search `{job="serenova"} |= "backup"`. What do you see?
3. **Find the cause:** have a friend or a script request an odd URL at a random moment. Use only Grafana to find when it happened, and how many times.

## Test yourself

1. When would you look at metrics, and when at logs?
2. Your app logs plain text with `console.log`. What would JSON logs let you search for that you can't now?
3. Why must logs never contain passwords or personal data?
4. Splunk and Datadog are hosted products with similar goals. What would make a company pay for them?
