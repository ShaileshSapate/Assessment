Manual Deployment steps : 

Prerequisite : 
1. Self signed Certificate is generated with correct  password 

1. Run below commands for azure login from cli
    az login
    az account set --subscription "mention your subscription name"

2. Terraform infra (running from local)
    terraform init
    terraform plan
    terraform apply

3. run below command to zip index.html file for Deployment
    mkdir site
    cp index.html site/
    cd site
    zip site.zip index.html

4. deploy zip using cli

    az webapp deployment source config-zip --resource-group az-rg-devops-poc --name hello-world-webapp-security-poc  --src site.zip
