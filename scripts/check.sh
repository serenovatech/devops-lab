#!/usr/bin/env bash
# Checks a finished lab: ./scripts/check.sh <staging|ansible|docker|jenkins|terraform|k8s|monitoring|logging|alerts>
# It only reads. "staging" checks your real app and is worth running after every lab.
set -u

failures=0

pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; failures=$((failures + 1)); }
check() {
  local name="$1"
  shift
  if "$@" > /dev/null 2>&1; then pass "$name"; else fail "$name"; fi
}
url_ok() { curl -fsS -m 5 "$1"; }
contains() { curl -fsS -m 5 "$1" | grep -q "$2"; }
has_container() { [ -n "$(docker ps -q --filter "name=$1")" ]; }

case "${1:-}" in
  staging)
    check "Real app is ready on port 8080" url_ok http://localhost:8080/readyz
    check "Real app publishes metrics" contains http://127.0.0.1:9100/metrics '^pfm_ready 1'
    check "Other site still answers on port 80" url_ok http://localhost/
    ;;
  ansible)
    check "Terraform is installed" terraform version
    check "k3s is installed" k3s --version
    check "VMware Tools is running" systemctl is-active open-vm-tools
    ;;
  docker)
    check "Image poultry-lab:1.0 exists" docker image inspect poultry-lab:1.0
    check "Lab copy is ready on port 3200" url_ok http://localhost:3200/readyz
    check "Lab copy publishes metrics" contains http://127.0.0.1:9200/metrics '^pfm_ready 1'
    ;;
  jenkins)
    check "Jenkins answers on port 8081" url_ok http://localhost:8081/login
    check "Jenkins can use Docker" docker exec jenkins docker version
    check "Deployed copy is ready on port 3300" url_ok http://localhost:3300/readyz
    ;;
  terraform)
    check "First copy is ready on port 4000" url_ok http://localhost:4000/readyz
    check "Second copy is ready on port 4001" url_ok http://localhost:4001/readyz
    ;;
  k8s)
    check "k3s is running" systemctl is-active k3s
    check "Node is Ready" sh -c "kubectl get nodes --no-headers | grep -qw Ready"
    check "Two app pods are ready" sh -c "[ \$(kubectl -n poultry-lab get pods -l app=poultry --no-headers | grep -c '1/1') -ge 2 ]"
    check "Service is ready on port 30080" url_ok http://localhost:30080/readyz
    ;;
  monitoring)
    check "Prometheus is healthy" url_ok http://localhost:9090/-/healthy
    check "Prometheus reads the real app" sh -c \
      "curl -fsS -m 5 'http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22poultry-staging%22%7D' | grep -q '\"1\"\\]'"
    check "Alert rules are loaded" contains http://localhost:9090/api/v1/rules PfmNotReady
    check "Grafana is healthy" url_ok http://localhost:3001/api/health
    check "Prometheus restarts after a reboot" sh -c \
      "docker inspect lab-monitoring-prometheus-1 --format '{{.HostConfig.RestartPolicy.Name}}' | grep -q unless-stopped"
    ;;
  logging)
    # Loki takes about a minute to become ready after starting.
    for _ in $(seq 1 30); do
      url_ok http://localhost:3100/ready > /dev/null 2>&1 && break
      sleep 3
    done
    check "Loki is ready" url_ok http://localhost:3100/ready
    curl -s -m 5 http://localhost:8080/healthz > /dev/null
    sleep 7
    check "nginx logs reached Loki" sh -c \
      "curl -fsS -m 5 -G http://localhost:3100/loki/api/v1/query_range --data-urlencode 'query={job=\"nginx\"}' | grep -q '\"values\"'"
    check "App logs reached Loki" sh -c \
      "curl -fsS -m 5 -G http://localhost:3100/loki/api/v1/query_range --data-urlencode 'query={job=\"serenova\"}' --data-urlencode 'since=168h' | grep -q '\"values\"'"
    ;;
  alerts)
    check "Alertmanager is healthy" url_ok http://localhost:9093/-/healthy
    check "Alert receiver is running" has_container alert-log
    check "Prometheus knows Alertmanager" contains http://localhost:9090/api/v1/alertmanagers 9093
    ;;
  *)
    echo "Usage: $0 <staging|ansible|docker|jenkins|terraform|k8s|monitoring|logging|alerts>"
    exit 2
    ;;
esac

if [ "$failures" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$failures check(s) failed."
  exit 1
fi
