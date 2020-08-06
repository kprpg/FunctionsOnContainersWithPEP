## Check to make sure where you are - ie which directory
pwd
## Create a local folder for the function project with JS, using docker.
func init LocalFunctionsProject --worker-runtime node --language javascript --docker
## Once you are done creating the local project, you dont have to run the above each time.
## Just CD to the folder and then run/test the func 'locally' using "func start"
## FOR WSL Folder -> /home/gpillai
## For Windows Folder ->/mnt/c/Users/gpillai/poc/LocalFunctionsProject
## For some reason nvm defaults to v14.x - which does not work with V3 of Functions. It needs to be either 10.0.0 or 12.0.0.
## Following commands are to deactivate the nvm from v 14.0 and set it to 10.9.0
nvm deactivate
nvm install 10.9.0
cd LocalFunctionsProject
## New up the function
func new --name HttpExample --template "HTTP Trigger"

## Make sure you have the correct node version installed. Functions runtime v3 requires node version 10 or higher.
## Test locally
func start

## Now to upload to the Function in Azure, created with "Docker" as hosting option
## ATT POC SUB -> ES-CUS-AT&TEXHIBIT02-DEV-ATTDEVOPSPATTERN
export APP_SUBSCRIPTION_ID=<<Your-Sub-ID>>
az login
az account set --subscription $APP_SUBSCRIPTION_ID

## Use --force, as by default the Function App created via the portal is using docker for .NET and NOT 
##                  the one for node. --force, will replace the container with the correct container.
func azure functionapp publish func-poc-docker --force 

######################################################
#####                                            #####
##### Docker push/pulls - wetting the docker env ##### 
#####                                            #####
##### Docker BEGIN ###################################
pwd
cd /home/azureuser/docker
## Pull an image from Microsoft's docker-hub which is relevant for functions.
## Reference - https://hub.docker.com/_/microsoft-azure-functions-node 
## NOTE: Docker could not work from WSL. So I had to switch to Windows command prompt.
docker login 
## Just sanity check on docker - do a pull, spin it up, shut down etc.
docker pull mcr.microsoft.com/azure-functions/node:3.0
## Now docker commands related to azure func.
## CD to the correct folder.
cd C:\Users\XXXXX\AppData\Local\Packages\CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc\LocalState\rootfs\home\gpillai\LocalFunctionsProject
## Build the docker for the function
docker build --tag <Replace_Tag_String>/azurefunctionsimage:v1.0.0 .
## run it locally and check
docker  run -p 8080:80 -it <Replace_Tag_String>/azurefunctionsimage:v1.0.2
## Verify function by going to http://localhost:8080
## Push the image to docker hub
docker push <Replace_Tag_String>/azurefunctionsimage:v1.0.0
##### Docker END   ###################################

### Azure parts ####
## Switch Terminal to WSL/bash, before running the below.
export APP_SUBSCRIPTION_ID=<<Replace_Su_ID>>
export POC_PREFIX=poc
export FUNC_STORAGE_ACCOUNT=$POC_PREFIX"storeacct"
export RG=AzureFunctionsContainers-rg
export LOC=WestUS
export APP_NAME=func-poc-docker
az login
az account set --subscription $APP_SUBSCRIPTION_ID

az group create --name $RG --location $LOC

## Create the ACR
az acr create --resource-group myResourceGroup \
  --name myContainerRegistry007 --sku Basic
az storage account create --name  $FUNC_STORAGE_ACCOUNT --location $LOC --resource-group $RG --sku Standard_LRS
az functionapp plan create --resource-group $RG --name myPremiumPlan --location $LOC --number-of-workers 1 --sku EP1 --is-linux
## CLI for Function app's container settings
## az functionapp config container show --name MyFunctionApp --resource-group MyResourceGroup
## az functionapp config container set --docker-custom-image-name MyDockerCustomImage --docker-registry-server-password StrongPassword --docker-registry-server-url https://{azure-container-registry-name}.azurecr.io --docker-registry-server-user DockerUserId --name MyFunctionApp --resource-group MyResourceGroup
az functionapp create --name $APP_NAME --storage-account $FUNC_STORAGE_ACCOUNT --resource-group $RG --plan myPremiumPlan --deployment-container-image-name girishpillai/azurefunctionsimage:v1.0.0 --functions-version 3
az functionapp create --name $APP_NAME --storage-account $FUNC_STORAGE_ACCOUNT --resource-group $RG --plan myPremiumPlan --deployment-container-image-name girishpillai/azurefunctionsimage:v1.0.0  --runtime node --functions-version 3
az storage account show-connection-string --resource-group $RG --name $FUNC_STORAGE_ACCOUNT --query connectionString --output tsv        
## Get the storage account's connection string into a variable.
storageConnectionString=$(az storage account show-connection-string --resource-group $RG \
     --name $FUNC_STORAGE_ACCOUNT --query connectionString --output tsv)
## Set the Function APP's storage account connection string via appsettings
az functionapp config appsettings set --name $APP_NAME --resource-group $RG --settings AzureWebJobsStorage=$storageConnectionString

###########  CI/CD ############################################
## Enabling CI-CD of the docker images to Azure function app ##
CI_CD_URL=$(az functionapp deployment container config --enable-cd --query CI_CD_URL --output tsv --name $APP_NAME --resource-group  $RG)
## OR ##
az functionapp deployment container show-cd-url --name $APP_NAME --resource-group $RG

## Copy the deployment webhook URL to the clipboard.
## Open Docker Hub, sign in, and select Repositories on the nav bar. 
## Locate and select image, select the Webhooks tab, specify a Webhook name, 
## paste your URL in Webhook URL, and then select Create:
## WEBHOOK-NAME=continuousdeployment4poc
## URL for CI-CD = https://$func-poc-docker:<<XX>>@func-poc-docker.scm.azurewebsites.net/docker/hook

## Enable SSH
## https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-function-linux-custom-image?tabs=bash%2Cazurecli&pivots=programming-language-javascript#enable-ssh-connections

## Write to an Azure Storage queue
## Retrieve the Azure Storage connection string
func azure functionapp fetch-app-settings func-poc-docker
## Add an output binding definition to the function

################################ Docker BEGIN   ###################################
## Now docker commands related to azure func.
## CD to the correct folder.
cd C:\Users\<<XXX>>\AppData\Local\Packages\CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc\LocalState\rootfs\home\gpillai\LocalFunctionsProject
## Build the docker for the function
## Switch to a "Command Prompt" terminal
docker build --tag <<Replace_Tag_String>>/azurefunctionsimage:v1.0.0 .
## run it locally and check
docker  run -p 8080:80 -it <<Replace_Tag_String>>/azurefunctionsimage:v1.0.0
## Verify function by going to http://localhost:8080
## Push the image to docker hub
docker push <<Replace_Tag_String>>/azurefunctionsimage:v1.0.0
################################ Docker END   ###################################

## Check the Storage queue for message insertion
export AZURE_STORAGE_CONNECTION_STRING=<TO_BE_FILLED> ##
az storage queue list --output tsv
## Note that below will sequentially get the messages one by one, and then finally when all msgs are retrieved will return empty
echo `echo $(az storage message get --queue-name outqueue -o tsv --query '[].{Message:content}') | base64 --decode`
