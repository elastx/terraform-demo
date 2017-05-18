#!/usr/bin/env bash
#
# Run this before running terraform commands
#
echo "Please enter your username: "
read -r OS_USERNAME_INPUT
export TF_VAR_user_name=$OS_USERNAME_INPUT

echo "Please enter your tenant name: "
read -r OS_TENANT_INPUT
export TF_VAR_tenant_name=$OS_TENANT_INPUT

echo "Please enter your OpenStack Password: "
read -sr OS_PASSWORD_INPUT
export TF_VAR_password=$OS_PASSWORD_INPUT

