# Terraform Demo

This is just a quickstart for using terraform on Elastx. It creates:

| \# | Resource |
|----|----------|
1 | Router
2 | Subnets, web and db
4 | instances, 2 web, 2 db
2 | floating IPs for web cluster
2 | Server Groups with anti-affiniy (web, db) makes sure instances aren't on same physical hardware
3 | Security Groups "wk-ssh-sg", "wk-web-sg" and "wk-db-sg"
1 | Key pair "demo\_rsa"

Default user is changed to "elastx" with cloud-config.

## File structure
| Name | Description |
|------|-------------|
README.md | This file, obviously
demo\_rsa(\|\\.pub) | SSH keypair, only to be used for this demonstration
terraform.tf | The terraform manifest with all defined resources
terraform-openrc.sh | should be run initially to setup username, tenant and password
terraform.tfstate(\|\\.backup) | tfstate and tfstate.backup so that terraform can keep track on changes


## How to use

Make sure you have installed [Terraform](https://www.terraform.io/)

First off, run the terraform-openrc.sh script. It will ask about username, tenant and password. Then run "terraform plan". If that fails, make sure you've used the correct credentials (runt terraform-openrc.sh again)

Last, "terraform apply" will install

```bash
$ . ./terraform-openrc.sh
[...]
$ terraform plan
$ terraform apply
```

You should now have a fully working environment with everything described in the beginning of this README.
