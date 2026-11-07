# Lab 0: Prepare the VM

**Goal:** a safety net, and a clear picture of what's already on `serenova-devops`.

## 1. Take a snapshot first

This is your undo button for every later lab. In VMware choose **VM → Snapshot → Take Snapshot**, and name it `before-devops-labs`.

A snapshot uses extra disk space as the VM changes, and D: has about 41 GB free. Delete it when you finish the labs.

## 2. Optional: give the VM more memory

It has 3.9 GB. Raising it to 6 GB makes labs 4 and 6 much smoother, and your laptop can spare it if you close other VMs and heavy apps.

1. **⚠ REAL STAGING:** shut the VM down from inside Ubuntu. Your apps will be offline for a few minutes.
2. In VMware choose **Edit virtual machine settings → Memory**, and set 6144 MB.
3. Start the VM. Your apps and MySQL start by themselves, but the GitHub runners may not. See step 4.

## 3. Log in

From Windows:

```bash
ssh super@192.168.224.140
```

If it can't connect, the address may have changed. Run `hostname -I` in the VM's window to find the new one.

**Work as `super`, not `root`.** Your prompt should start `super@`. If it starts `root@`, run `exit`. As root, `~` means `/root`, so files end up where the labs can't find them, and one mistake can do far more damage. Use `sudo` only for the commands that need it.

## 4. Survey the VM

Before changing a system, learn what's on it.

| Question | Command |
|---|---|
| How much memory is free? | `free -h` |
| How much disk is free? | `df -h /` |
| Which services are running? | `systemctl list-units --type=service --state=running` |
| Did anything fail? | `systemctl --failed` |
| What is listening on which port? | `sudo ss -tlnp` |
| Which containers exist? | `docker ps -a` |
| Which site does nginx serve? | `ls /etc/nginx/sites-enabled` |

When we surveyed this VM on 7 November, we found:

- **Real app:** nginx serves it on port 8080, and the app itself listens only on `127.0.0.1:3000`.
- **Other site:** Serenova Tech is on port 80. Leave it alone.
- **Prometheus and Grafana:** stopped since the last reboot. You'll fix this in lab 7.
- **Both GitHub runners:** stopped, so deployments can't run. You'll investigate this now.
- **The clock:** it was about 11 hours behind the laptop, while reporting `synchronized: yes`, and it corrected itself later. This may happen after the laptop sleeps. Compare `date` with your Windows clock. A wrong clock can break HTTPS and GitHub connections, and makes logs hard to line up.

## 5. Investigate the runners

Your Poultry runner is set to start at boot, but it stopped. Read why:

```bash
journalctl -u "actions.runner.teenShirt-serenova-poultry-erp*" -n 30 --no-pager
```

Find the line starting `Failed to create a session`, and read it carefully. It says GitHub deleted this runner's registration, because it hadn't connected recently. Restarting can't fix that, because GitHub no longer recognises the runner.

Leave it for now. While it's stopped, nothing can deploy to this VM, which makes the earlier labs safer. You'll register it again in lab 10.

## 6. Get the Poultry code

This is a separate clone for the labs. Your deployed app runs from `/opt/serenova`, so nothing here affects it:

```bash
git clone https://github.com/teenShirt/serenova-poultry-erp.git ~/poultry
```

```bash
git -C ~/poultry switch test
```

## Check

```bash
curl -s localhost:8080/readyz
```

You should see `"status":"ready"` and `"version":"2.3.1"`.

## Test yourself

1. Why take a snapshot before doing anything else?
2. The app listens on `127.0.0.1:3000`, but users connect to port 8080. What connects the two?
3. Why does the app's metrics port, 9100, listen only on `127.0.0.1`?
4. Your lab report says all services recovered after a reboot, but Prometheus and the runners are down now. What might explain the difference?
