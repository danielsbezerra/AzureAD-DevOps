Setup Terraform
az account list --query "[].{name:name, subscriptionId:id, tenantId:tenantId}"
az account set --subscription="b8bcab55-0c0d-4960-8e48-dd897062af89"
az account set --subscription="148fb67d-04a8-48ba-8dab-0d3b8c99e1bb"
az account list-locations

Create a service principal
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"
az ad sp create-for-rbac --name ServicePrincipalName

Lists service principal
az ad sp list --show-mine --query '[].{"id":"appId", "tenant":"appOwnerTenantId"}'

If local, not Cloud Shell...
#!/bin/sh
echo "Setting environment variables for Terraform"
export ARM_SUBSCRIPTION_ID=your_subscription_id
export ARM_CLIENT_ID=your_appId
export ARM_CLIENT_SECRET=your_password
export ARM_TENANT_ID=your_tenant_id


# Install the Azure PowerShell module
Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Connect to Azure with a browser sign in token
Connect-AzAccount

# Loops
variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}

resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}


# Terraform LOG
export TF_LOG_PATH=./terraform.log
export TF_LOG=TRACE --TRACE, DEBUG, INFO, WARN or ERROR