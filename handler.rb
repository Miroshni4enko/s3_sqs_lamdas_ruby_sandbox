require 'json'
require 'aws-sdk-sqs'
require 'aws-sdk-s3'
require 'logger'

def s3processor(event:, context:)
  logger.info("event #{event.to_json}")

  response = s3_client.get_object({
    bucket: event["Records"].first["s3"]["bucket"]["name"],
    key: event["Records"].first["s3"]["object"]["key"],
  })

  logger.info("event #{response.to_s}")

  json_data = JSON.parse(response.body.read)
  send_sqs_message(json_data.to_s)
end

def sqs_client
  @sqs_client ||= Aws::SQS::Client.new
end

def s3_client
  @s3_client ||= Aws::S3::Client.new
end

def send_sqs_message(message)
  sqs_client.send_message(
    queue_url: ENV['QUEUE_URL'],
    message_body: message
  )
  logger.info('Created SQS message')
rescue Aws::SQS::Errors::ServiceError => e
  logger.error(e)
end

def logger
  @logger ||= Logger.new($stdout)
end
