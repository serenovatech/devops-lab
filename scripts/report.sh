#!/usr/bin/env bash
# Prints a live status report for this VM as Markdown. It only reads, and never needs sudo.
#   ./scripts/report.sh                         show it now
#   ./scripts/report.sh > reports/status.md     save it
set -u

APP=http://localhost:8080
PROM=http://localhost:9090

# Marks a result, so that problems stand out.
ok() { echo "✅ $1"; }
bad() { echo "❌ $1"; }
note() { echo "⚠️ $1"; }

service_row() {
  local state since
  state=$(systemctl is-active "$1" 2>/dev/null)
  since=$(systemctl show "$1" --property=ActiveEnterTimestamp --value 2>/dev/null)
  if [ "$state" = active ]; then
    echo "| $2 | $(ok active) | since ${since:-unknown} |"
  else
    echo "| $2 | $(bad "$state") | |"
  fi
}

prom_query() {
  curl -fsS -m 5 -G "$PROM/api/v1/query" --data-urlencode "query=$1" 2>/dev/null |
    jq -r '.data.result[0].value[1] // empty' 2>/dev/null
}

percent() {
  [ -n "$1" ] && [ "$1" != NaN ] && awk -v v="$1" 'BEGIN { printf "%.2f%%", v * 100 }'
}

echo "# Staging Environment Status"
echo
echo "**Generated:** $(date '+%Y-%m-%d %H:%M:%S %Z') · **Host:** $(hostname) · **Environment:** staging, not production"
echo

echo "## Application"
echo
ready=$(curl -s -m 5 "$APP/readyz")
if echo "$ready" | jq -e '.status == "ready"' > /dev/null 2>&1; then
  echo "- **Readiness:** $(ok ready)"
else
  echo "- **Readiness:** $(bad "${ready:-no response}")"
fi
echo "- **Version:** $(echo "$ready" | jq -r '.version // "unknown"')"
echo "- **Release:** \`$(echo "$ready" | jq -r '.release // "unknown"' | cut -c1-7)\`"
echo "- **Database schema:** $(echo "$ready" | jq -r '"\(.schema // "?") of \(.expectedSchema // "?")"')"
echo "- **Response time:** $(curl -s -m 5 -o /dev/null -w '%{time_total}' "$APP/readyz")s"
echo

echo "## Services"
echo
echo "| Service | State | Detail |"
echo "|---|---|---|"
service_row serenova "Poultry app"
service_row mysql "MySQL"
service_row nginx "nginx"
service_row docker "Docker"
for unit in $(systemctl list-units --type=service --all --no-legend --plain 'actions.runner.*' | awk '{print $1}'); do
  name=$(echo "$unit" | sed -E 's/actions\.runner\.[^-]+-([^.]+)\..*/\1/')
  service_row "$unit" "GitHub runner: $name"
done
echo

echo "## Resources"
echo
echo "- **Uptime:** $(uptime -p)"
echo "- **Load:** $(cut -d' ' -f1-3 /proc/loadavg) on $(nproc) CPUs"
echo "- **Memory:** $(free -h | awk 'NR==2 {print $7 " available of " $2}')"
echo "- **Swap used:** $(free -h | awk 'NR==3 {print $3 " of " $2}')"
disk=$(df --output=pcent / | tail -1 | tr -dc 0-9)
disk_text="$(df -h --output=avail / | tail -1 | xargs) free, ${disk}% used"
if [ "$disk" -ge 85 ]; then echo "- **Disk:** $(bad "$disk_text")"; else echo "- **Disk:** $(ok "$disk_text")"; fi

server_date=$(curl -sI -m 5 https://github.com | grep -i '^date:' | cut -d' ' -f2- | tr -d '\r')
if [ -n "$server_date" ]; then
  drift=$(($(date +%s) - $(date -d "$server_date" +%s)))
  if [ "${drift#-}" -le 5 ]; then
    echo "- **Clock:** $(ok "${drift}s from GitHub's time")"
  else
    echo "- **Clock:** $(bad "${drift}s from GitHub's time")"
  fi
else
  echo "- **Clock:** $(note "could not compare")"
fi
echo

echo "## Monitoring"
echo
if ! curl -fsS -m 3 "$PROM/-/healthy" > /dev/null 2>&1; then
  echo "$(bad 'Prometheus is not running, so there is no SLO data and no alerts can fire.')"
else
  echo "- **Prometheus:** $(ok running)"
  staging='job="poultry-staging"'
  availability=$(prom_query "1 - sum(rate(pfm_http_requests_total{$staging,route=~\"/api/.*\",status=~\"5..\"}[1h])) / sum(rate(pfm_http_requests_total{$staging,route=~\"/api/.*\"}[1h]))")
  latency=$(prom_query "sum(rate(pfm_http_request_duration_seconds_bucket{$staging,route=~\"/api/.*\",le=\"0.5\"}[1h])) / sum(rate(pfm_http_request_duration_seconds_count{$staging,route=~\"/api/.*\"}[1h]))")
  echo "- **Availability, last hour (target 99.5%):** $(percent "$availability" || echo 'no API traffic to measure')"
  echo "- **Requests within 500 ms, last hour (target 95%):** $(percent "$latency" || echo 'no API traffic to measure')"
  alerts=$(curl -fsS -m 5 "$PROM/api/v1/alerts" | jq -r '.data.alerts[] | select(.state == "firing") | "- ❌ \(.labels.alertname): \(.annotations.summary)"')
  echo
  if [ -n "$alerts" ]; then echo "**Alerts firing:**"; echo; echo "$alerts"; else echo "**Alerts firing:** $(ok none)"; fi
fi
if curl -fsS -m 3 http://localhost:9093/-/healthy > /dev/null 2>&1; then
  echo "- **Alertmanager:** $(ok running)"
else
  echo "- **Alertmanager:** $(bad 'not running, so nobody would be notified')"
fi
if curl -fsS -m 3 http://localhost:3100/ready > /dev/null 2>&1; then
  echo "- **Log collection:** $(ok running)"
else
  echo "- **Log collection:** $(note 'not running')"
fi
echo

echo "## Backups"
echo
# The app logs backup failures but not successes, so logs alone can't prove that a backup worked.
failure=$(journalctl -u serenova --no-pager -o short-iso --since "7 days ago" 2>/dev/null | grep -i 'backup failed' | tail -1 | cut -d' ' -f1,4- | cut -c1-130)
if [ -n "$failure" ]; then
  echo "- **Latest failure, last 7 days:** $(note "\`$failure\`")"
else
  echo "- **Failures, last 7 days:** $(ok none logged)"
fi
newest=$(sudo -n ls -1t /opt/serenova/shared/data/backups 2>/dev/null | head -1)
if [ -n "$newest" ]; then
  echo "- **Newest backup file:** \`$newest\`"
else
  echo "- **Newest backup file:** $(note 'not checked. Run: sudo ls -lt /opt/serenova/shared/data/backups')"
fi
echo

echo "## Logs"
echo
if [ -s /var/log/nginx/access.log ] || [ ! -s /var/log/nginx/access.log.1 ]; then
  echo "- **nginx log file:** $(ok 'writing to access.log')"
else
  echo "- **nginx log file:** $(note 'access.log is empty while access.log.1 has data. nginx may have missed a log rotation')"
fi
errors=$(journalctl -u serenova --since "24 hours ago" -p err --no-pager -o cat 2>/dev/null | grep -vc '^-- No entries')
echo "- **App error lines, last 24 hours:** $errors"
echo
