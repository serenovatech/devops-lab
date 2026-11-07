# Lab 1: Git and GitHub

**Git** records every change to your files. **GitHub** stores that history online and adds pull requests, so changes can be reviewed.

You'll fix a real problem: your postmortem has an open action item to replace the `OWNER` placeholder in your alert links.

**This is safe:** only a push to `main` starts a deployment, and this lab doesn't touch `main`.

## 1. Fix a real issue on a branch

On **Windows**, in your Poultry repository:

```bash
cd /d/Project/Poultry-web-app
```

```bash
git switch test && git pull
```

```bash
git switch -c fix-runbook-links
```

In `infra/helm/poultry/files/alerts.yml`, replace every `OWNER/Poultry-web-app` with `teenShirt/serenova-poultry-erp`. Then look at what changed before saving it:

```bash
git diff
```

```bash
git add infra/helm/poultry/files/alerts.yml
```

```bash
git commit -m "Point alert runbook links at the real repository"
```

```bash
git push -u origin fix-runbook-links
```

`git add` chooses what goes into a commit, `git commit` saves it, and `git push` uploads it. Your `docs/LAB-REPORT.md` isn't committed yet, and this `git add` leaves it out.

## 2. Open a pull request

1. On GitHub, open a **pull request** from `fix-runbook-links`.
2. **Change the base branch to `test`.** It may default to `main`.
3. Read your own diff as a reviewer would, then click **Merge**.

The merge is a push to `test`, so your **CI**, **Container** and **Infra** workflows now run. Watch them in the **Actions** tab. These run on GitHub's machines, so your stopped runner doesn't matter. Only the deployment uses it.

Your branching rule: work goes to `test`, and only tested work goes on to `main`. Don't merge `test` into `main` until lab 10.

## 3. Put this lab project on GitHub

Jenkins reads its pipeline from GitHub in lab 4. On Windows:

```bash
cd /d/Project/devops-lab
```

```bash
git init -b main
```

```bash
git add . && git commit -m "Start the DevOps lab"
```

Create a **public** repository named `devops-lab` on GitHub, without a README. This guide uses the `serenovatech` organization; use your own account or organization name if it differs. Then:

```bash
git remote add origin https://github.com/serenovatech/devops-lab.git
```

```bash
git push -u origin main
```

Then on the VM:

```bash
git clone https://github.com/serenovatech/devops-lab.git ~/devops-lab
```

```bash
chmod +x ~/devops-lab/scripts/*.sh && ~/devops-lab/scripts/check.sh staging
```

From now on, you can edit on Windows and `git push`, then `git pull` on the VM.

## Break it: a merge conflict

In `devops-lab`, on Windows:

1. Make branch `a`, change the first line of this file, and commit.
2. Go back to `main`, make branch `b`, change the same line differently, and commit.
3. Run `git merge a` while on `b`. Git stops and marks the conflict.
4. Edit the file to keep what you want, remove the `<<<<` markers, then `git add` and `git commit`.

## Useful commands

| Command | What it shows or does |
|---|---|
| `git status` | What has changed |
| `git diff` | The exact lines that changed |
| `git log --oneline` | The history |
| `git revert <commit>` | Safely undoes a commit with a new commit |

## Test yourself

1. Which workflows ran after your merge, and which didn't? Look at the `on:` section of each file in `.github/workflows`.
2. Why is `*.tfstate` in this project's [.gitignore](../.gitignore)?
3. Your Poultry repository is public, so anyone can read it. What must never be committed to it?
4. SVN is centralized and Git is distributed. What can you do offline with Git that you can't with SVN?
