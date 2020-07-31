module.exports = async function (context, req) {
    const {DefaultAzureCredential, ManagedIdentityCredential} = require('@azure/identity');
    const {SecretClient} = require('@azure/keyvault-secrets');
    const credential = new ManagedIdentityCredential();
    
    const vaultName = process.env.KV_NAME;
    const url = `https://${vaultName}.vault.azure.net`;      
    const client = new SecretClient(url, credential);
    
    // Replace value with your secret name here
    const secretName = process.env.APP_MESSAGE;
    if (req.query.name || (req.body && req.body.name)) {
        const secret = await client.getSecret(secretName);
        context.res = {
            // status: 200, /* Defaults to 200 */
            body: "Hello Secret: " + "[Your secret value is: " + secret.value + "]"
        };
    }
    else {
        context.res = {
            status: 400,
            body: "Please pass a name on the query string or in the request body"
        };
    }
};