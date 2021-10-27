const AWS = require('aws-sdk')

const CloudFront = new AWS.CloudFront()
const CodePipeline = new AWS.CodePipeline()

module.exports.default = async (event, context) => {
  const jobId = event['CodePipeline.job'].id
  try {
    const DistributionId = event['CodePipeline.job'].data.actionConfiguration.configuration.UserParameters
    await CloudFront.createInvalidation({
      DistributionId,
      InvalidationBatch: {
        CallerReference: context.awsRequestId,
        Paths: { Quantity: 1, Items: [ '/*' ] }
      }
    }).promise()
    await CodePipeline.putJobSuccessResult({ jobId }).promise()
  } catch (e) {
    console.error(e)
    await CodePipeline.putJobFailureResult({
      jobId,
      failureDetails: {
        message: e.toString(),
        type: 'JobFailed'
      }
    }).promise()
  }
}
