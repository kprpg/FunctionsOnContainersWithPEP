module.exports = async function (context, myBlob) {
    const uuidv1 = require('uuid/v1')
    context.log("JavaScript blob trigger function processed blob \n Blob:", context.bindingData.blobTrigger, "\n Blob Size:", myBlob.length, "Bytes");
    data =context.bindingData.name;
    context.bindings.tableBinding = [];

    context.bindings.tableBinding.push({
        PartitionKey: uuidv1(),
        RowKey: data,
        Name: data
        });
    
    context.done();
};