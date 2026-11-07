# Lab 10: Capstone

Use everything together, with less step-by-step help. These missions finish real work: your `docs/LAB-REPORT.md` still lists rollback, restore and load testing as **not run**.

**Before you start:** take a new snapshot, and read each mission through. Missions 1 to 4 are **⚠ REAL STAGING**. It's staging and not production, but check that nothing you care about is only stored there.

## Mission 1: Bring deployments back

In lab 0 you found that GitHub deleted the Poultry runner's registration, because it hadn't connected recently. It needs registering again.

- [ ] On GitHub, open **Settings → Actions → Runners → New self-hosted runner**, and copy the token. It lasts one hour, and it's a secret, so don't share or commit it
- [ ] In `/opt/actions-runner-serenova-poultry`, follow GitHub's `config.sh` step as the folder's owner, using `--replace` and the label `serenova-staging`. The setup steps are in your Poultry `scripts/deploy/setup-staging-vm.sh`
- [ ] Start the service, and confirm that it shows **Idle** on GitHub
- [ ] Reboot, and confirm that it comes back by itself
- [ ] Add it to your runbook: if this VM stays off for a long time, the runner may need registering again

Leave the `Serenova-techno` runner to its own project.

## Mission 2: Ship a real release

Your lab 1 fix is on `test`, and the runner now works.

- [ ] Open a pull request from `test` to `main`, and wait for all the checks
- [ ] Merge it, and watch **Deploy** run on your own runner
- [ ] Confirm the new `release` from `curl -s localhost:8080/readyz`
- [ ] Watch the deployment on your Grafana dashboard

## Mission 3: Rollback drill (report lab 2)

Follow the rollback steps in your own `docs/DEPLOYMENT.md`, and time yourself.

- [ ] Note the current and previous releases with `ls -1t /opt/serenova/releases`
- [ ] Roll back to the previous release, and confirm `/readyz` shows it
- [ ] **Read the steps about database schema first.** A release that changed the schema may not roll back cleanly
- [ ] Roll forward again
- [ ] Record the time taken in your lab report

## Mission 4: Restore drill (report lab 6)

A backup counts only once you've restored it. Your `docs/RECOVERY.md` has the steps, and `serenova_restore_test` already exists for this.

- [ ] Run `npm run restore-test` as that document describes. It restores into the test database, not the real one
- [ ] Do **not** run `restore-database` for this drill. That one replaces real data
- [ ] Confirm that the result shows as passed, and time it against your 1-hour goal
- [ ] Check that a copy of `BACKUP_ENCRYPTION_KEY` exists somewhere off this VM. Without it, your backups can't be read

## Mission 5: Load test (report lab 7)

Use the lab copy, not real staging.

- [ ] Start the lab copy and monitoring
- [ ] Run a load tool in a container against `http://VM_IP:3200`, such as `grafana/k6`, and start with a few users
- [ ] Watch latency on your dashboard, and find the load where fewer than 95% of requests finish within 500 ms, your SLO
- [ ] Record what ran out first: CPU, memory or database connections

## Mission 6: Outage drill with a real alert

Your first drill ended with "nobody was notified". Repeat it properly on the lab copy. Have someone else, or a script with a random `sleep`, stop one of its containers.

- [ ] Find out from a notification, not by being told
- [ ] Confirm the impact on a dashboard, and find the cause in the logs
- [ ] Fix it, and confirm that the alert resolves
- [ ] Write a blameless postmortem using your `docs/postmortem-template.md`

## Mission 7: Close your action items

Your postmortem lists five. After these labs, you should be able to finish them all in your Poultry repository:

- [ ] Add Alertmanager notifications (lab 9)
- [ ] Fix `runbook_url` in `alerts.yml` (lab 1)
- [ ] Add VM commands to `docs/runbooks/app-not-ready.md`
- [ ] Have systemd restart MySQL automatically with `Restart=on-failure`
- [ ] Run the restore drill (mission 4)

Then fix the two other issues found while preparing these labs:

- [ ] `PfmHighMemory` fires at 900 MB, but the Helm chart limits the app to 768 Mi, so it can't fire on Kubernetes
- [ ] `PfmNotReady` uses `max()`, which hides an outage when more than one copy runs (lab 7)

## Where to go next

- **Helm:** turn `k8s/` into a chart, then compare it with `infra/helm/poultry`
- **Argo CD:** deploy from Git automatically (GitOps), using your `infra/argocd`
- **Move real staging to containers:** use what you learned in lab 3
- **Production:** apply these drills to a real server only when you've done them all here
