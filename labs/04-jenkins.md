# Lab 4: Jenkins (CI/CD)

**Continuous Integration** tests every change automatically. **Continuous Deployment** ships changes that pass. **Jenkins** is an automation server you run yourself.

**In your Poultry project:** GitHub Actions does this job. Here you'll rebuild the same idea in Jenkins, and it deploys only to a lab copy on port 3300.

This is the heaviest lab, with Jenkins, MySQL and your tests running together. Stop other lab stacks first, and raise the VM's memory if the build struggles.

```bash
~/devops-lab/scripts/stop-all.sh
```

## 1. Start Jenkins

```bash
cd ~/devops-lab/jenkins
```

```bash
DOCKER_GID=$(getent group docker | cut -d: -f3) docker compose up -d --build
```

Get the first-login password:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Open `http://VM_IP:8081`. Port 8080 is taken by nginx, so Jenkins uses 8081. Paste the password, choose **Install suggested plugins**, and create your admin user.

## 2. Read the pipeline

Open [Jenkinsfile](../Jenkinsfile), and compare it with `.github/workflows/ci.yml` in your Poultry repository.

```text
Get the code → Start test database → Format, types, lint, tests → Build image → Smoke test → Deploy to lab staging
```

If any stage fails, the later ones don't run.

## 3. Create the job

1. Choose **New Item**, name it `poultry`, and select **Pipeline**.
2. Under **Pipeline**, set **Definition** to **Pipeline script from SCM**.
3. Set **SCM** to **Git**, and enter `https://github.com/teenShirt/devops-lab.git`.
4. Change **Branch** to `*/main`. The default of `*/master` won't find your branch.
5. Keep **Script Path** as `Jenkinsfile`, and click **Save**.
6. Click **Build Now**.

Open the build and read **Console Output**. Expect about 20 minutes the first time: the test image alone takes around 4 minutes to build, and your 152 tests around 8 on this VM. Memory gets tight, and we saw over 1 GB of swap in use, so close other stacks first. After the first run, the button becomes **Build with Parameters**.

When it's green:

```bash
curl -s localhost:3300/readyz
```

The `release` is the commit Jenkins built, so you can trace what's running back to the code.

## 4. Build automatically

GitHub can't reach a VM behind NAT, so Jenkins will check GitHub on a timer instead. This is called polling:

1. In the job, choose **Configure**.
2. Under **Triggers**, tick **Poll SCM**.
3. Set the schedule to `H/5 * * * *`, which means about every 5 minutes.

This watches the `devops-lab` repository, where the Jenkinsfile lives. Push a small change to it, and watch a build start by itself.

Your GitHub Actions runner solves the same NAT problem differently: it reaches out to GitHub and asks for work.

## Check

```bash
cd ~/devops-lab && ./scripts/check.sh jenkins && ./scripts/check.sh staging
```

## Break it

Do this on a practice branch of Poultry that you never merge. On Windows:

```bash
cd /d/Project/Poultry-web-app && git switch test && git switch -c jenkins-practice
```

1. **Failing test:** break a test, commit, and push. Build with `BRANCH` set to `jenkins-practice`. It goes red at the tests stage, and `localhost:3300` keeps serving the old version. Bad code never reached the lab staging copy.
2. **Bad container:** undo that, then change the `CMD` in the Dockerfile to a file that doesn't exist. Tests pass, but **Smoke test** catches it.
3. **Clean up:** delete the branch with `git switch test && git push origin --delete jenkins-practice && git branch -D jenkins-practice`.

## Finish

```bash
./scripts/stop-all.sh
```

## Test yourself

1. What is the difference between continuous delivery and continuous deployment?
2. Why smoke test the image if the tests already passed?
3. Jenkins has access to the Docker socket. Why is that risky?
4. Jenkins or GitHub Actions: which would you choose for this project, and why?
