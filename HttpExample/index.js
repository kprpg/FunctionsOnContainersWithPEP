/*
module.exports = async function (context, req) {
    context.log('JavaScript HTTP trigger function processed a request.');

    const name = (req.query.name || (req.body && req.body.name));
    const responseMessage = name
        ? "Hello, " + name + ". This HTTP triggered function executed successfully."
        : "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.";

    context.res = {
        // status: 200, // Defaults to 200 //
        body: responseMessage
        // End Comment
    };
}
*/
module.exports = async function (context, req) {
    context.log('ATT POC-JavaScript HTTP trigger function processed a request.');

    if (req.query.name || (req.body && req.body.name)) {
        // Add a message to the Storage queue,
        // which is the name passed to the function.
        context.bindings.msg = "-> Test Message from AT&T Inc ::-> [******" +(req.query.name || req.body.name)+ "******]" ;
        context.res = {
            // status: 200, /* Defaults to 200 */
            body: "!!! Hello Howdy !!! Test Message for AT&T Inc:-> " + (req.query.name || req.body.name) 
        };
    }
    else {
        context.res = {
            status: 400,
            body: "Oho! Please pass a name on the query string or in the request body"
            // end comments.
        };
    }
};