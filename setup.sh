#!/bin/bash
echo 'creating workspaces'
envs=("production" "staging" "dev" "shared")
for env in "${envs[@]}"
do
  terraform workspace select $env || terraform workspace new $env
done

echo 'terraform init'
terraform init
