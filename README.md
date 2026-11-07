# DevOps Lab

Learn the main DevOps tools on your real system: the `serenova-devops` VM and the Poultry app running on it.

## How your real system stays safe

This VM runs your staging app, so the labs keep two things apart:

| | Real staging | Lab copy |
|---|---|---|
| App | `http://VM_IP:8080` | `http://VM_IP:3200` (other labs use their own ports) |
| Database | MySQL service, `serenova` | Separate MySQL containers, empty at the start |
| Rule | Only read from it, unless a step says otherwise | Break it as much as you like |

- Steps that change real staging are marked **⚠ REAL STAGING**. Everything else leaves it alone.
- Run `./scripts/check.sh staging` after each lab. It confirms your real app is still healthy.
- Take a VMware snapshot before you start. [Lab 0](labs/00-prepare-the-vm.md) explains how.

## The labs

Do them in order. Each one builds on the last.

| Lab | Tool | What you'll do | Time |
|---|---|---|---|
| [0](labs/00-prepare-the-vm.md) | VMware, Linux | Take a snapshot, survey the VM, get the code | 30 min |
| [1](labs/01-git-and-github.md) | Git, GitHub | Fix a real item from your lab report through a branch | 45 min |
| [2](labs/02-ansible.md) | Ansible | Install the missing tools from code | 45 min |
| [3](labs/03-docker.md) | Docker, Compose | Run a lab copy of the Poultry app and its database | 1 hour |
| [4](labs/04-jenkins.md) | Jenkins | Build a pipeline that tests and deploys Poultry | 2 hours |
| [5](labs/05-terraform.md) | Terraform | Create the app and its database from code | 1 hour |
| [6](labs/06-kubernetes.md) | Kubernetes (k3s) | Deploy, scale, update and roll back Poultry | 2 hours |
| [7](labs/07-monitoring.md) | Prometheus, Grafana | Bring monitoring back, and make it survive reboots | 1 hour |
| [8](labs/08-logging.md) | Fluent Bit, Loki | Collect and search your real app's logs | 45 min |
| [9](labs/09-alerts.md) | Alertmanager, Slack | Fix "nobody was notified" from your postmortem | 1 hour |
| [10](labs/10-capstone.md) | All of them | Finish the drills your lab report still lists as not run | 3 hours |

## Your report

- **Live status:** run `./scripts/report.sh` on the VM any time for current figures. Save a copy with `./scripts/report.sh > reports/status-$(date +%F).md`.
- **Lab record:** [reports/lab-record.md](reports/lab-record.md) tracks what you've done, what you measured and what's still open.

This VM is staging, so the report says so. Grafana on port 3001 gives you a view that updates continuously.

## Memory limits

The VM has 3.9 GB RAM and 2 CPUs, and about 2.3 GB is free with your apps running.

- Run one lab stack at a time. Run `./scripts/stop-all.sh` before you start the next one. It stops lab stacks and keeps their data, and never touches your real app.
- For a smoother time, raise the VM to 6 GB RAM. Labs 4 and 6 benefit most. [Lab 0](labs/00-prepare-the-vm.md) explains how.

## Addresses

`VM_IP` is currently `192.168.224.140`. It comes from DHCP, so it can change.

| Service | Address | Lab |
|---|---|---|
| Other site (Serenova Tech) | `http://VM_IP` | Not part of the labs |
| **Real staging app** | `http://VM_IP:8080` | Not a lab copy |
| Lab copy of Poultry | `http://VM_IP:3200` | 3 |
| Jenkins | `http://VM_IP:8081` | 4 |
| Copy deployed by Jenkins | `http://VM_IP:3300` | 4 |
| Terraform copies | `http://VM_IP:4000`, `:4001` | 5 |
| Poultry on Kubernetes | `http://VM_IP:30080` | 6 |
| Prometheus | `http://VM_IP:9090` | 7 |
| Grafana (`admin` / `admin`) | `http://VM_IP:3001` | 7 |
| Alertmanager | `http://VM_IP:9093` | 9 |

These lab passwords are only for this private VM. Don't reuse them on a real server.

## How this maps to your course

| Course category | In these labs | Similar tools you can now pick up quickly |
|---|---|---|
| Version control and SCM | Git, GitHub | Bitbucket, GitLab. SVN works differently: it is centralized |
| CI/CD | Jenkins, your GitHub Actions | Travis CI, CircleCI |
| Configuration management | Ansible | Chef, Puppet |
| Containers | Docker | Podman, LXC |
| Orchestration | Kubernetes (k3s) | OpenShift, which extends Kubernetes. Apache Mesos |
| Infrastructure as Code | Terraform | OpenTofu, which runs these same files. AWS CloudFormation |
| Monitoring | Prometheus, Grafana | Zabbix, Nagios, OpenNMS |
| Logging | Fluent Bit, Loki | Fluentd, ELK Stack, Splunk, Datadog |
| Collaboration | Slack alerts | Microsoft Teams |

**Why not ELK?** Elasticsearch alone commonly needs a few GB of memory, and this VM doesn't have that to spare. Fluent Bit and Loki teach the same idea, and your Poultry project uses Loki too.

## Layout

```text
compose.yaml  Lab 3: a lab copy of Poultry with its own database
ansible/      Lab 2: adds the missing tools
Jenkinsfile   Lab 4: the pipeline (jenkins/ runs Jenkins itself)
terraform/    Lab 5: infrastructure as code
k8s/          Lab 6: Kubernetes manifests
monitoring/   Labs 7 and 9: Prometheus, Grafana, Alertmanager
logging/      Lab 8: Fluent Bit
scripts/      check.sh tests a lab; stop-all.sh frees memory
labs/         The step-by-step instructions
```

On the VM, this project lives at `~/devops-lab`, next to a clone of Poultry at `~/poultry`.

Start with [lab 0](labs/00-prepare-the-vm.md).
