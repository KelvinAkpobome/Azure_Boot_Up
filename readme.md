
## Automation with Ansible and terraform - ansible integration with  terraform 

Provisioning Linux servers with the azure provider on an Ubuntu machine, 



## Prerequiste

You need to install ansible, depending on your Package manager

Variable files you will need in ansible/group_vars/all/vault.yml

Ansible downloads terraform binary, then spins up the infrastructure as configured

```yml
subscription_id:  cXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

app_id: eXXXXXXXXX-XXXXXXXXXXX-XXXXXXXX

password: CXXXXXXXXX_.XXXXXXXXXX--7XXXXXXXXXX

tenant: XXXXXXX-XXX-XXXXX-XXXXXXXXXX-XXXXXXXXXXXXX
```

## Outcome

You will have your ip addresses for both VMs in your ansible/inventory/hosts file as follows

```yml
[master]
XXX.XXX.XXX.XXX

[worker]
XXX.XXX.XXX.XXX

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```