const AWS = require('aws-sdk');

exports.handler = (event, context, callback) => {
    let sns = new AWS.SNS();

    let eventDetail = event["detail"];

    let id = eventDetail['resourceArn'];
    let status = eventDetail['state'];
    let account = event['account'];
    let region = event['region'];
    let vault = eventDetail['backupVaultName'];
    let time = event['time'];

    let subject = `Backup Report - Omnisite - ${id}`;
    let message = `
    Device: ${id}
    Status: Failure
    Job: ${id}
    Time: ${time}
    Account: ${account}
    Region: ${region}
    Vault: ${vault}
    `;
     
    sns.publish({
       TopicArn: 'arn:aws:sns:us-east-2:574224739898:Backup-Alerts',
       Message: message, 
       Subject: subject
    }, function(error, data){
       if(error) console.log(error, error.stack);
       callback(error, data);
     });
};