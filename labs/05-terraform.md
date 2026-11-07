# Lab 5: Terraform (Infrastructure as Code)

**Terraform** creates infrastructure from files. You describe what should exist, it compares that with what does exist, and it shows you a **plan** before making changes.

Ansible configures a machine that already exists. Terraform creates the machine, network or other resource.

**In your Poultry project:** `infra/terraform/proxmox` creates VMs. This lab creates Docker containers instead, so it needs no cloud account and costs nothing. The workflow is the same.

You need the `poultry-lab:1.0` image from lab 3.

```bash
~/devops-lab/scripts/stop-all.sh
```

```bash
cd ~/devops-lab/terraform
```

## 1. The core workflow

Download the Docker provider:

```bash
terraform init
```

Check the files:

```bash
terraform fmt -check && terraform validate
```

Preview the changes. Read the `+` lines, and notice that Terraform worked out the order by itself: network and volume, then MySQL, then the app.

```bash
terraform plan
```

Create everything. Type `yes` when asked:

```bash
terraform apply
```

MySQL takes a moment to start, and the app restarts until it connects. Then try it:

```bash
curl -s localhost:4000/readyz; echo; curl -s localhost:4001/readyz
```

## 2. Change something

```bash
terraform plan -var replicas=3
```

The plan adds exactly one container. Apply it with `terraform apply -var replicas=3`, then run `terraform apply` to go back to 2.

Note the difference between `~` (change in place), `-/+` (replace) and `-` (remove). Always read a plan before you approve it.

## 3. Understand state

Terraform records what it created in `terraform.tfstate`:

```bash
terraform state list
```

```bash
terraform output
```

Run `grep -c terraform-lab-only terraform.tfstate`. The password is stored in the state as plain text, even though it's marked `sensitive`. That's why state stays out of Git. Teams keep it in shared, locked remote storage.

## Check

```bash
cd ~/devops-lab && ./scripts/check.sh terraform && ./scripts/check.sh staging
```

## Break it: fix drift

Someone deletes a container by hand:

```bash
docker rm -f lab-tf-dev-app-1
```

From the `terraform` folder, `terraform plan` shows that it will be recreated. `terraform apply` puts it back.

Then try `terraform plan -var replicas=9`, and read the validation error. It comes from [variables.tf](../terraform/variables.tf).

## Bonus: OpenTofu

OpenTofu is the open source fork of Terraform. After you destroy these containers, follow the install guide at opentofu.org and run these same files with `tofu init`, `tofu plan` and `tofu apply`. CloudFormation has the same idea, but only for AWS.

## Finish

Remove what you created. This is one of Terraform's most useful features:

```bash
terraform destroy
```

## Test yourself

1. What does `terraform plan` protect you from?
2. What happens if you lose the state file?
3. What is drift, and how did you fix it here?
4. Read `infra/terraform/proxmox/main.tf` in your Poultry repository. What is the same as this lab, and what differs?
