#!/usr/bin/env bash
# Frees memory between labs. Stops every lab stack but keeps its data and images.
# Your real staging app, its MySQL, nginx and the GitHub runners are not touched.
cd "$(dirname "$0")/.."

docker compose down 2>/dev/null
docker compose -f monitoring/compose.yaml --profile logging down 2>/dev/null
docker stop jenkins poultry-jenkins jenkins-mysql > /dev/null 2>&1

terraform_containers=$(docker ps -q --filter name=lab-tf- 2>/dev/null)
if [ -n "$terraform_containers" ]; then
  docker stop $terraform_containers > /dev/null
fi

if systemctl is-active --quiet k3s 2>/dev/null; then
  sudo /usr/local/bin/k3s-killall.sh > /dev/null 2>&1
  echo "Stopped k3s."
fi

echo "All lab stacks are stopped."
free -h
