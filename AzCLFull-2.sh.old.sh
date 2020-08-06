# Please provide your subscription id here
## ATT POC SUB -> "My Azure Subscription"
export APP_SUBSCRIPTION_ID=<< Your Sub ID>>
# Please provide your unique prefix to make sure that your resources are unique
export APP_PREFIX=attfunctest
# Please provide your region, and make sure the region supports container hosting for Functions.
export LOCATION=EastUS ## (East US 2 does not support using containers for functions)
# Please provide your OS
export IS_LINUX=true
export OS_TYPE=Linux

export VNET_PREFIX="10.0."

export APP_PE_DEMO_RG=$APP_PREFIX"-funcdemo-rg"
export DEMO_VNET=$APP_PREFIX"-funcdemo-vnet"
export DEMO_VNET_CIDR=$VNET_PREFIX"0.0/16"
export DEMO_VNET_APP_SUBNET=app_subnet
export DEMO_VNET_APP_SUBNET_CIDR=$VNET_PREFIX"1.0/24"
export DEMO_VNET_PL_SUBNET=pl_subnet
export DEMO_VNET_PL_SUBNET_CIDR=$VNET_PREFIX"2.0/24"

export DEMO_FUNC_PLAN=$APP_PREFIX"-prem-func-plan"
export DEMO_APP_STORAGE_ACCT=$APP_PREFIX"appstore"
export DEMO_FUNC_STORAGE_ACCT=$APP_PREFIX"fncstore"
export DEMO_FUNC_NAME=$APP_PREFIX"-demofunc-app"
export DEMO_APP_STORAGE_CONFIG="FileStore"
export DEMO_ACR=$APP_PREFIX"AzAcr" ## Name must be unique. So please replace "FuncDockerAcr"

export DEMO_APP_VM=devtestvm
export DEMO_APP_VM_ADMIN=azureuser
export DEMO_VM_IMAGE=MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest
export DEMO_VM_SIZE=Standard_DS2_v2
export DEMO_APP_AKV=$APP_PREFIX"-demo-akv1"

export KV_SECRET_APP_MESSAGE="APP-MESSAGE"
export KV_SECRET_APP_MESSAGE_VALUE="This is a test message for function-on-container-POC"
export KV_SECRET_APP_MESSAGE_VAR="APP_MESSAGE"
export KV_SECRET_APP_KV_NAME_VAR="KV_NAME"

## Azure Login
az login
## Make sure to set correct subscription ID if you have multiple subs
az account set --subscription $APP_SUBSCRIPTION_ID
# Create Resource Group
az group create -l $LOCATION -n $APP_PE_DEMO_RG
# Create VNET and App Service delegated Subnet
az network vnet create -g $APP_PE_DEMO_RG -n $DEMO_VNET --address-prefix $DEMO_VNET_CIDR \
 --subnet-name $DEMO_VNET_APP_SUBNET --subnet-prefix $DEMO_VNET_APP_SUBNET_CIDR
# Create Subnet to create PL, VMs etc.
az network vnet subnet create -g $APP_PE_DEMO_RG --vnet-name $DEMO_VNET -n $DEMO_VNET_PL_SUBNET \
    --address-prefixes $DEMO_VNET_PL_SUBNET_CIDR

#############  BEGIN ACR and Private DNS for ACR ############################################
## Create the ACR with Premium SKU and "admin user" must be enabled. In portal, go to the ACR ->access keys, enable and note down password.
az acr create --resource-group $APP_PE_DEMO_RG --name $DEMO_ACR --sku Premium --admin-enabled true ## must use Premium SKU
## To get Access token
az acr login -n  $DEMO_ACR --expose-token
## Copy the access token for use below.
## docker login loginServer -u 00000000-0000-0000-0000-000000000000 -p accessToken
docker login loginServer -u 00000000-0000-0000-0000-000000000000 -p accessToken
## docker login $DEMO_ACR.azurecr.io -u 00000000-0000-0000-0000-000000000000 -p <<Token>>
## Fill values below before executing
## Go to the portal, go to the ACR -> Access Keys and note down the below. These values are required for Function App Creation.
ACR-AdminUser=<Your_ACR_ADMIN_USER_NAME>
ACR-AdminPassword=<Your_ACR_ADMIN_PASSWORD>
## export ACR Resource ID ###
export ACR_RESOURCE_ID="/subscriptions/"$APP_SUBSCRIPTION_ID"/resourceGroups/"$APP_PE_DEMO_RG"/providers/Microsoft.ContainerRegistry/registries/"$DEMO_ACR

####################### BEGIN DOCKER ##############################
## Login before connection to ACR
## IMPORTANT: CD to folder where "Dockerfile" lives
cd /mnt/c/Users/gpillai/source/repos/Func-on-Containers-with-PEP
az acr login -n $DEMO_ACR  -t
az acr build --image azurefunctionsimage:v1.0.0 -r $DEMO_ACR .
## For docker commands switch to windows CMD terminal
## DOCKER build . -f ./Dockerfile -t $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0
## DOCKER build --tag $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0 .
## docker tag azurefunctionsimage $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0 ## BUILD command already tags, so not needed.
## DOCKER push $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0
## DOCKER inspect funcdockeracr.azurecr.io/azurefunctionsimage:v1.0.0
######################## END DOCKER #################################

####################### BEGIN DOCKER ##############################
## Login before connection to ACR
az acr login --name $DEMO_ACR 
## For docker commands switch to windows CMD terminal
DOCKER build . -f ./Dockerfile -t $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0
## DOCKER build --tag $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0 .
##docker tag azurefunctionsimage $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0 ## BUILD command already tags, so not needed.
DOCKER push $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0
## DOCKER inspect funcdockeracr.azurecr.io/azurefunctionsimage:v1.0.0
######################## END DOCKER #################################




# Create VM to host
# - DNS
# - NodeJS
# - VS Code
# - Azure CLI
## For Windows Server.
az vm create -n $DEMO_APP_VM -g $APP_PE_DEMO_RG --image MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest \
    --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET --public-ip-sku Standard --size $DEMO_VM_SIZE --admin-username $DEMO_APP_VM_ADMIN
# Once the VM is installed, deploy the following tools on it. OR better yet deploy a Windows 10 VM with the tools such as
##                          already present in it, so you don't have to install it manually yourself.
# Install VS Code - https://code.visualstudio.com/download
# Setup Local environment to create Functions - https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function-azure-cli?tabs=bash%2Cbrowser&pivots=programming-language-javascript#configure-your-local-environment
################ ABOVE: Complete the VM Setup before moving next #######################

############### STORAGE ###############
# Create the storage account to be used by all the functions for housekeeping
az storage account create --name $DEMO_FUNC_STORAGE_ACCT --location $LOCATION --resource-group $APP_PE_DEMO_RG --sku Standard_LRS --kind StorageV2

# Create the storage account to be used by the function with storage Blob trigger
az storage account create --name $DEMO_APP_STORAGE_ACCT --location $LOCATION --resource-group $APP_PE_DEMO_RG --sku Standard_LRS --kind StorageV2

##
az storage account show -n $DEMO_APP_STORAGE_ACCT --query networkRuleSet
az storage account update --resource-group $APP_PE_DEMO_RG --name $DEMO_APP_STORAGE_ACCT --default-action Allow
# Create Blob container for trigger 
az storage container create --account-name $DEMO_APP_STORAGE_ACCT --name datafiles --auth-mode login
az storage container create --account-name $DEMO_APP_STORAGE_ACCT --name samples-workitems --auth-mode login

# Create Table Store Table for results
az storage table create --name FileLogs --account-name $DEMO_APP_STORAGE_ACCT 
# Create Table Store Table for results
az storage queue create --name outqueue --account-name $DEMO_APP_STORAGE_ACCT 

############# Function Plan and Function App #######################
# Create Premium Function Plan

## Create the PLAN with premium SKU based on Linux
az functionapp plan create --resource-group $APP_PE_DEMO_RG --name $DEMO_FUNC_PLAN --location $LOCATION --number-of-workers 1 --sku EP2 --is-linux
## Create the actual Function app within the plan environment based on container image as the hosting for the function code.
## Here the runtime is node, function version is "3" and a deployment container is specified. Replace UserName/Password below
az functionapp create --name $DEMO_FUNC_NAME --storage-account $DEMO_FUNC_STORAGE_ACCT --resource-group $APP_PE_DEMO_RG \
     --plan $DEMO_FUNC_PLAN --deployment-container-image-name $DEMO_ACR.azurecr.io/azurefunctionsimage:v1.0.0  --runtime node --functions-version 3 \
     --docker-registry-server-password <ACR_AdminPassword> --docker-registry-server-user <ACR-Adminuser>

## Wait for a few minutes, and then go to the Function App and make sure all of your functions are loaded up.
## You can do some sanity test to make sure the functions are working, before creating Priv.DNS Zones and PEPs.

## The deployment-container-image-name parameter specifies the image to use for the function app. 
## You can use the "az functionapp config container show" command to view information about the image used for deployment. 
az functionapp config container show --name $DEMO_FUNC_NAME --resource-group $APP_PE_DEMO_RG
## You can also use "the az functionapp config container set" command to deploy from a different image.
## If you need to delete, use the below delete cli call.
## az functionapp plan delete --name $DEMO_FUNC_PLAN --resyource-group $APP_PE_DEMO_RG

# Assign MSI for Premium Function App
# Please save the output and take a note of the ObjecID and save it as $APP_MSI
az functionapp identity assign -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME

# Capture identity from output
APP_MSI=$(az webapp show --name $DEMO_FUNC_NAME -g $APP_PE_DEMO_RG --query identity.principalId -o tsv)
export APP_MSI

# Create Key Vault
az keyvault create --location $LOCATION --name $DEMO_APP_AKV --resource-group $APP_PE_DEMO_RG --enable-soft-delete true

# Set Key Vault Secrets
# Please  take a note of the Secret Full Path and save it as KV_SECRET_DB_UID_FULLPATH
az keyvault secret set --vault-name $DEMO_APP_AKV --name "$KV_SECRET_APP_MESSAGE" --value "$KV_SECRET_APP_MESSAGE_VALUE"

# Capture the KV URI
# az keyvault show --name $DEMO_APP_AKV --resource-group $APP_PE_DEMO_RG
export KV_URI="/subscriptions/"$APP_SUBSCRIPTION_ID"/resourceGroups/"$APP_PE_DEMO_RG"/providers/Microsoft.KeyVault/vaults/"$DEMO_APP_AKV

# Set Policy for Web App to access secrets
az keyvault set-policy -g  $APP_PE_DEMO_RG --name $DEMO_APP_AKV --object-id $APP_MSI --secret-permissions get list --verbose

# Get the connection string for App Storage Account for trigger
# Create Web App variable
STORAGE_ACCESS_KEY=$(az storage account show-connection-string -g $APP_PE_DEMO_RG -n $DEMO_APP_STORAGE_ACCT --query connectionString -o tsv)

az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings $KV_SECRET_APP_MESSAGE_VAR="$KV_SECRET_APP_MESSAGE"
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings $KV_SECRET_APP_KV_NAME_VAR="$DEMO_APP_AKV"
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings $DEMO_APP_STORAGE_CONFIG="$STORAGE_ACCESS_KEY"

# Set Private DNS Zone Settings
##  WEBSITE_DNS_SERVER=168.62.129.16 
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings "WEBSITE_DNS_SERVER"="168.63.129.16"
az functionapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --settings "WEBSITE_VNET_ROUTE_ALL"="1"
#
# Create Private Links
#
# Prepare the Subnet
az network vnet subnet update -g $APP_PE_DEMO_RG -n $DEMO_VNET_PL_SUBNET --vnet-name $DEMO_VNET --disable-private-endpoint-network-policies
az network vnet subnet update -g $APP_PE_DEMO_RG -n $DEMO_VNET_PL_SUBNET --vnet-name $DEMO_VNET --disable-private-link-service-network-policies

### Set up PEP and Private DNS Zones for the ACR ####
PRIVATE_ACR_IP=$(az network private-endpoint create -g $APP_PE_DEMO_RG -n funcacrpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id "$ACR_RESOURCE_ID" --connection-name funcacrpeconn -l $LOCATION --group-id "registry" --query customDnsConfigs[0].ipAddresses[0] -o tsv)

## Obtain the IP addresses for ACR Private EndPoints
NETWORK_INTERFACE_ID=$(az network private-endpoint show --name funcacrpe --resource-group $APP_PE_DEMO_RG --query 'networkInterfaces[0].id' --output tsv)
PRIVATE_IP=$(az resource show --ids $NETWORK_INTERFACE_ID  --query 'properties.ipConfigurations[1].properties.privateIPAddress' --output tsv)
##PRIVATE_IP=10.0.2.10 ## "az resource show --ids" had some issues. Used "az network private-endpoint show" and used the output for the two IPs below.
DATA_ENDPOINT_PRIVATE_IP=$(az resource show --ids $NETWORK_INTERFACE_ID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' --output tsv)
##DATA_ENDPOINT_PRIVATE_IP=10.0.2.9
## ACR Private DNS Zone
export AZUREACR_ZONE=privatelink.azurecr.io
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREACR_ZONE
az network private-dns record-set a create --name $DEMO_ACR --zone-name privatelink.azurecr.io --resource-group $APP_PE_DEMO_RG
az network private-dns record-set a create --name ${DEMO_ACR}.${LOCATION}.data --zone-name privatelink.azurecr.io --resource-group $APP_PE_DEMO_RG
## ACR Private DNS - Records
az network private-dns record-set a add-record --record-set-name $DEMO_ACR --zone-name privatelink.azurecr.io --resource-group $APP_PE_DEMO_RG --ipv4-address $PRIVATE_IP
az network private-dns record-set a add-record --record-set-name ${DEMO_ACR}.${LOCATION}.data --zone-name privatelink.azurecr.io --resource-group $APP_PE_DEMO_RG --ipv4-address $DATA_ENDPOINT_PRIVATE_IP
## ACR Private DNS link
az network private-dns link vnet create -g $APP_PE_DEMO_RG --virtual-network $DEMO_VNET --zone-name $AZUREACR_ZONE --name acrdnsLink --registration-enabled false
#############  END ACR and Private DNS for ACR ############################################
# Create Key Vault Private Link
# Get the Resource ID of the Key Vault from the Portal, assign it to KV_RESOURCE_ID and create private link
PRIVATE_KV_IP=$(az network private-endpoint create -g $APP_PE_DEMO_RG -n kvpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id "$KV_URI" --connection-name kvpeconn -l $LOCATION --group-id "vault" --query customDnsConfigs[0].ipAddresses[0] -o tsv)

# Create App Storage Private Links
# Get the Resource ID of the App Storage from the Portal, assign it to APP_STORAGE_RESOURCE_ID and create private link
export APP_STORAGE_RESOURCE_ID="/subscriptions/"$APP_SUBSCRIPTION_ID"/resourceGroups/"$APP_PE_DEMO_RG"/providers/Microsoft.Storage/storageAccounts/"$DEMO_APP_STORAGE_ACCT
PRIVATE_APP_BLOB_IP=$(az network private-endpoint create -g $APP_PE_DEMO_RG -n funcblobpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id "$APP_STORAGE_RESOURCE_ID" --connection-name funcblobpeconn -l $LOCATION --group-id "blob" --query customDnsConfigs[0].ipAddresses[0] -o tsv)
PRIVATE_APP_TABLE_IP=$(az network private-endpoint create -g $APP_PE_DEMO_RG -n functablepe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id "$APP_STORAGE_RESOURCE_ID" --connection-name functableconn -l $LOCATION --group-id "table" --query customDnsConfigs[0].ipAddresses[0] -o tsv)
PRIVATE_APP_QUEUE_IP=$(az network private-endpoint create -g $APP_PE_DEMO_RG -n funcqueuepe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id "$APP_STORAGE_RESOURCE_ID" --connection-name funcqueueconn -l $LOCATION --group-id "queue" --query customDnsConfigs[0].ipAddresses[0] -o tsv)


# Creating Forward Lookup Zones in the DNS server you created above
# You may be using root hints for DNS resolution on your custom DNS server.
# Please add 168.63.129.16 as default forwarder on you custom DNS server.
# https://docs.microsoft.com/en-us/powershell/module/dnsserver/set-dnsserverforwarder?view=win10-ps

#   Create the zone for: vault.azure.net
#       Create an A Record for the Key Vault with the name and its private endpoint address

# Switch to custom DNS on VNET
export DEMO_APP_VM_IP="10.0.2.4"
az network vnet update -g $APP_PE_DEMO_RG -n $DEMO_VNET --dns-servers $DEMO_APP_VM_IP

# AKV Private DNS Zones
export AZUREKEYVAULT_ZONE=privatelink.vaultcore.azure.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREKEYVAULT_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREKEYVAULT_ZONE -n $DEMO_APP_AKV -a $PRIVATE_KV_IP
az network private-dns link vnet create -g $APP_PE_DEMO_RG --virtual-network $DEMO_VNET --zone-name $AZUREKEYVAULT_ZONE --name kvdnsLink --registration-enabled false

export AZUREBLOB_ZONE=privatelink.blob.core.windows.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREBLOB_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREBLOB_ZONE -n $DEMO_APP_STORAGE_ACCT -a $PRIVATE_APP_BLOB_IP
az network private-dns link vnet create -g $APP_PE_DEMO_RG --virtual-network $DEMO_VNET --zone-name $AZUREBLOB_ZONE --name blobdnsLink --registration-enabled false

export AZURETABLE_ZONE=privatelink.table.core.windows.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZURETABLE_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZURETABLE_ZONE -n $DEMO_APP_STORAGE_ACCT -a $PRIVATE_APP_TABLE_IP
az network private-dns link vnet create -g $APP_PE_DEMO_RG --virtual-network $DEMO_VNET --zone-name $AZURETABLE_ZONE --name tablednsLink --registration-enabled false

export AZUREQUEUE_ZONE=privatelink.queue.core.windows.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREQUEUE_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREQUEUE_ZONE -n $DEMO_APP_STORAGE_ACCT -a $PRIVATE_APP_QUEUE_IP
az network private-dns link vnet create -g $APP_PE_DEMO_RG --virtual-network $DEMO_VNET --zone-name $AZUREQUEUE_ZONE --name queuednsLink --registration-enabled false

#
# Change KV firewall - allow only PE access
# Verify it's locked down (click on Secrets from browser)
#

# Attach Web App to the VNET (VNET integration)
az functionapp vnet-integration add -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME --vnet $DEMO_VNET --subnet $DEMO_VNET_APP_SUBNET

# enable virtual network triggers
az resource update -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME/config/web --set properties.functionsRuntimeScaleMonitoringEnabled=1 --resource-type Microsoft.Web/sites

# Now restart the webapp
az functionapp restart -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME
# ...and verify it still has access to KV

# Get the webapp resource id
az functionapp show -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME

export FUNC_APP_RESOURCE_ID="/subscriptions/"$APP_SUBSCRIPTION_ID"/resourceGroups/"$APP_PE_DEMO_RG"/providers/Microsoft.Web/sites/"$DEMO_FUNC_NAME

##################################################################################################
# !!!!!!!!!!!!!!!!!!!!!!!!Stop Here Before Creating the Private Endpoint for Function!!!!!!!!!!!!!
# You should now use Docker push to push the function's code which is now part of the container
# Test the App to make sure that functions are running
##################################################################################################

# Create Web App Private Link
PRIVATE_APP_IP=$(az network private-endpoint create -g $APP_PE_DEMO_RG -n funcpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id $FUNC_APP_RESOURCE_ID --connection-name funcpeconn -l $LOCATION --group-id "sites" --query customDnsConfigs[0].ipAddresses[0] -o tsv)

export AZUREWEBSITES_ZONE=privatelink.azurewebsites.net
az network private-dns zone create -g $APP_PE_DEMO_RG -n $AZUREWEBSITES_ZONE
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREWEBSITES_ZONE -n $DEMO_FUNC_NAME -a $PRIVATE_APP_IP
az network private-dns record-set a add-record -g $APP_PE_DEMO_RG -z $AZUREWEBSITES_ZONE -n $DEMO_FUNC_NAME".scm" -a $PRIVATE_APP_IP

# Link zones to VNET
az network private-dns link vnet create -g $APP_PE_DEMO_RG -n funcpe-link -z $AZUREWEBSITES_ZONE -v $DEMO_VNET -e False

az webapp log tail -g $APP_PE_DEMO_RG -n $DEMO_FUNC_NAME




