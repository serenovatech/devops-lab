# Lab 9: Alerts and Slack

A dashboard only helps if someone is looking at it. **Alerts** come to you. Prometheus decides when a rule is broken, and **Alertmanager** decides who hears about it.

Your postmortem found exactly this gap: *"Nobody was notified: no Alertmanager."* This lab closes that action item.

## 1. Start the stack

```bash
cd ~/devops-lab && docker compose up -d && docker compose -f monitoring/compose.yaml up -d
```

Read [alerts-lab.yml](../monitoring/alerts-lab.yml) and [alertmanager.yml](../monitoring/alertmanager.yml). Alerts go to a small [receiver](../monitoring/alert-log.js) that prints them, so you don't need a Slack account yet.

## 2. Fire your first alert, on the lab copy

Open `http://VM_IP:9090/alerts` and leave it open. In one SSH window, watch the receiver:

```bash
cd ~/devops-lab && docker compose -f monitoring/compose.yaml logs -f alert-log
```

In another, stop the lab copy's database. Real staging isn't affected:

```bash
cd ~/devops-lab && docker compose stop mysql
```

Watch `LabCopyNotReady` move through these states, which takes up to about 2 minutes:

```text
inactive → pending (waiting out "for: 1m") → firing → sent to Alertmanager → printed by the receiver
```

Start the database again, and watch for the `RESOLVED` message:

```bash
docker compose start mysql
```

The `for:` setting stops a brief blip from waking anyone up. Too short gives false alarms, and too long means slow detection. Your Poultry drill measured this trade-off: 3 min 22 s to detect, with a 3-minute hold.

## 3. Silence an alert

During planned work, you don't want alerts. Open `http://VM_IP:9093`, choose **New Silence**, add the matcher `alertname="LabCopyNotReady"`, and set 30 minutes. Stop the database again, and confirm the receiver stays quiet. Then start it, and remove the silence.

## 4. Send alerts to Slack (optional)

Your report mentions email or Telegram, which work the same way, and each has its own section in Alertmanager's config.

1. Create a free Slack workspace with a `#devops-lab` channel.
2. At api.slack.com/apps, create an app, turn on **Incoming Webhooks**, and add one for the channel.
3. Save the URL on the VM. It works like a password, so it's in `.gitignore` and must not be committed:

```bash
nano ~/devops-lab/monitoring/slack-webhook-url
```

4. In `monitoring/compose.yaml`, add this under the `volumes` of `alertmanager`:

```yaml
      - ./slack-webhook-url:/etc/alertmanager/slack-webhook-url:ro
```

5. In `monitoring/alertmanager.yml`, remove the `#` from the `slack_configs` block.
6. Apply it, then repeat step 2 to test:

```bash
docker compose -f monitoring/compose.yaml up -d --force-recreate alertmanager
```

Microsoft Teams works the same way, through a webhook.

## Check

```bash
./scripts/check.sh alerts && ./scripts/check.sh staging
```

## Break it

Add a rule to `alerts-lab.yml` with a typo in its query, then restart Prometheus:

```bash
docker compose -f monitoring/compose.yaml restart prometheus
```

Prometheus won't start with a bad rule file. Read its error with `docker compose -f monitoring/compose.yaml logs prometheus`, and fix it. Your Poultry `infra.yml` workflow catches this earlier by running `promtool` in CI.

## Finish

```bash
./scripts/stop-all.sh
```

## Test yourself

1. What does `for: 1m` do? What goes wrong if you remove it?
2. What is the difference between Prometheus's job and Alertmanager's job?
3. What makes a good alert? Should high CPU page someone at 3 AM if users are fine?
4. You fixed the `runbook_url` links in lab 1. Why should an alert link to a runbook?
