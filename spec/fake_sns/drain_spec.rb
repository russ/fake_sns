require "sinatra/base"
require 'json_expressions/rspec'
require "json"

RSpec.describe "Drain messages", :sqs do
  it "works for SQS" do
    topic = sns_resource.create_topic(name: "my-topic")
    queue_url = sqs.create_queue(queue_name: "my-queue").queue_url
    topic.subscribe(queue_url, protocol: "sqs", endpoint: "http://localhost:4569")

    topic.publish(message: JSON.generate({ sqs: "X" }))

    $fake_sns.drain(nil, queue_name: "my-queue")
    expect(sqs.receive_message(queue_url: queue_url, max_number_of_messages: 10).count).to eq(1)
  end

  it "works for SQS with a single message" do
    topic = sns_resource.create_topic(name: "my-topic")
    queue_url = sqs.create_queue(queue_name: "my-queue").queue_url
    topic.subscribe(queue_url, protocol: "sqs", endpoint: "http://localhost:4569")

    message_id = topic.publish(message: JSON.generate({ sqs: "X" }))
    topic.publish(message: JSON.generate({ sqs: "Y" }))

    $fake_sns.drain(message_id.message_id, queue_name: "my-queue")
    expect(sqs.receive_message(queue_url: queue_url, max_number_of_messages: 10).count).to eq(1)
  end

  it "works for HTTP" do
    requests = []
    _headers = []
    target_app = Class.new(Sinatra::Base) do
      get("/") { 200 } # check if server started
      post("/endpoint") do
        requests << request.body.read
        _headers << request.env
        200
      end
    end

    app_runner = Thread.new do
      target_app.set :port, 5051
      target_app.run!
    end

    topic = sns_resource.create_topic(name: "my-topic")
    subscription = topic.subscribe(endpoint: "http://localhost:5051/endpoint", protocol: "http")

    message_id = topic.publish(message: JSON.generate({ default: "X" }))

    wait_for { Faraday.new("http://localhost:5051").get("/").success? rescue false }

    $fake_sns.drain

    app_runner.kill

    expect(requests.size).to eq 1
    expect(requests.first).to match_json_expression(
      "Type"             => "Notification",
      "Message"          => "X",
      "MessageId"        => message_id.message_id,
      "Signature"        => "Fake",
      "SignatureVersion" => "1",
      "SigningCertURL"   => "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-f3ecfb7224c7233fe7bb5f59f96de52f.pem",
      "Subject"          => nil,
      "Timestamp"        => anything,
      "TopicArn"         => topic.arn,
      "UnsubscribeURL"   => "",
    )

    expect(_headers.size).to eq 1
    expect(_headers.first).to match_json_expression({
      "HTTP_X_AMZ_SNS_MESSAGE_TYPE"     => "Notification",
      "HTTP_X_AMZ_SNS_MESSAGE_ID"       => message_id.message_id,
      "HTTP_X_AMZ_SNS_TOPIC_ARN"        => topic.arn,
      "HTTP_X_AMZ_SNS_SUBSCRIPTION_ARN" => subscription.arn,
    }.ignore_extra_keys!)
  end

  def wait_for(&condition)
    Timeout.timeout 1 do
      until condition.call
        sleep 0.01
      end
    end
  end
end
