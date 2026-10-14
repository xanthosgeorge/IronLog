#!/usr/bin/env bash
# Run in Azure Cloud Shell (Bash), then copy the printed IDs to GitHub variables.
set -euo pipefail

az account set --subscription '56f7ae78-cd24-4946-b17a-eff2fe6250f1'
resource_group='rg-ironlog'
app_name='ironlog-app-george'
identity_name='ironlog-github-deploy'

az identity create --resource-group "$resource_group" --name "$identity_name" \
  --location italynorth --output none
client_id=$(az identity show -g "$resource_group" -n "$identity_name" --query clientId -o tsv)
principal_id=$(az identity show -g "$resource_group" -n "$identity_name" --query principalId -o tsv)
tenant_id=$(az identity show -g "$resource_group" -n "$identity_name" --query tenantId -o tsv)
subscription_id=$(az account show --query id -o tsv)
app_id=$(az webapp show -g "$resource_group" -n "$app_name" --query id -o tsv)

az identity federated-credential create --resource-group "$resource_group" \
  --identity-name "$identity_name" --name github-main \
  --issuer 'https://token.actions.githubusercontent.com' \
  --subject 'repo:xanthosgeorge/IronLog:ref:refs/heads/main' \
  --audiences 'api://AzureADTokenExchange' --output none

existing_role=$(az role assignment list --scope "$app_id" \
  --query "[?principalId=='$principal_id' && roleDefinitionName=='Website Contributor'].id | [0]" \
  --output tsv)
if [ -z "$existing_role" ]; then
  az role assignment create --assignee-object-id "$principal_id" \
    --assignee-principal-type ServicePrincipal --role 'Website Contributor' \
    --scope "$app_id" --output none
fi

az webapp config appsettings set -g "$resource_group" -n "$app_name" \
  --settings ASPNETCORE_ENVIRONMENT=Production SCM_DO_BUILD_DURING_DEPLOYMENT=false \
  --output none
az webapp config set -g "$resource_group" -n "$app_name" \
  --startup-file 'dotnet IronLog.Api.dll' --output none
az webapp update -g "$resource_group" -n "$app_name" --https-only true --output none

printf '\nGitHub repository variables (Settings > Secrets and variables > Actions > Variables):\n'
printf 'AZURE_CLIENT_ID=%s\nAZURE_TENANT_ID=%s\nAZURE_SUBSCRIPTION_ID=%s\n' \
  "$client_id" "$tenant_id" "$subscription_id"
