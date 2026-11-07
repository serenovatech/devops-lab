# Lab 2: Ansible

**Ansible** sets up machines from a file. You describe what should be true ("Terraform is installed"), and it makes only the changes needed. Your setup becomes repeatable and reviewable, instead of commands you hope to remember.

**In your Poultry project:** `infra/ansible/site.yml` hardens servers and installs k3s and Argo CD.

**⚠ REAL STAGING:** this lab installs software on the VM, including VMware Tools. [site.yml](../ansible/site.yml) doesn't change your app, MySQL, nginx, Docker or the runners. Read it before you run it, and make sure your snapshot exists.

## 1. Install Ansible

```bash
sudo apt install -y ansible
```

```bash
cd ~/devops-lab/ansible
```

## 2. Read the playbook

Open [site.yml](../ansible/site.yml). Notice:

- **Hosts** say which machines to change. [inventory.ini](../ansible/inventory.ini) says this VM changes itself.
- **Tasks** describe the end result, such as `state: present`.
- **Tags** let you run only part of it.
- **The Docker task only checks.** Your VM has Docker CE, and installing Ubuntu's `docker.io` would conflict with it. A playbook has to fit the real machine.

## 3. Preview, then run

`--check` shows what would change, without changing anything:

```bash
ansible-playbook -i inventory.ini site.yml --ask-become-pass --check --tags base
```

Now run it all. `--ask-become-pass` asks for your sudo password, and it takes a few minutes:

```bash
ansible-playbook -i inventory.ini site.yml --ask-become-pass
```

Read the `PLAY RECAP` line at the end. `failed` should be 0.

## 4. See idempotence

Run it again:

```bash
ansible-playbook -i inventory.ini site.yml --ask-become-pass
```

The recap should now say `changed=0`. Nothing needed doing. This property is called **idempotence**, and it makes Ansible safe to run repeatedly.

## 5. See the benefit

With VMware Tools running, VMware can now report the VM's address. On Windows:

```bash
"/c/Program Files (x86)/VMware/VMware Workstation/vmrun.exe" -T ws getGuestIPAddress 'D:\VM\serenova-devops.vmx'
```

Earlier this failed, because the Tools weren't running.

## 6. Make your own change

Add `ncdu` to the helper packages in `site.yml`, and run only that part:

```bash
ansible-playbook -i inventory.ini site.yml --ask-become-pass --tags base
```

Only the changed task reports `changed`. Commit the change.

## Check

```bash
cd ~/devops-lab && ./scripts/check.sh ansible && ./scripts/check.sh staging
```

## Break it: fix drift

Someone removes a package by hand:

```bash
sudo apt remove -y tree
```

Run the playbook with `--tags base`. Ansible notices and installs it again.

## Test yourself

1. What does idempotent mean, and why does it matter?
2. Ansible needs no agent on the machines it manages. How is that different from Chef and Puppet?
3. Why doesn't this playbook just use your Poultry repository's `site.yml`? Read that file's SSH and swap tasks.
4. What would you add to make the runners or monitoring part of this playbook?
