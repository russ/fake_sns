RSpec.describe "Subscribing", :sqs do

  it "lists subscriptions globally" do
    topic = sns_resource.create_topic(name: "my-topic")
    subscription = topic.subscribe("http://example.com", endpoint: "http://localhost:4579", protocol: "sqs")
    expect(sns_resource.subscriptions.map(&:arn)).to eq([subscription.arn])
  end

  it "filters by topic" do
    topic = sns_resource.create_topic(name: "my-topic")
    other_topic = sns_resource.create_topic(name: "my-topic-2")
    subscription = topic.subscribe("http://example.com", endpoint: "http://localhost:4579", protocol: "sqs")
    expect(topic.subscriptions.map(&:arn)).to eq([subscription.arn])
    expect(other_topic.subscriptions.map(&:arn)).to eq([])
  end

  it "needs an existing topic" do
    topic = sns_resource.topic("arn:aws:sns:us-east-1:5068edfd0f7ee3ea9ccc1e73cbb17569:not-exist")
    expect {
      topic.subscribe("http://example.com", endpoint: "http://localhost:4579", protocol: "sqs")
    }.to raise_error Aws::SNS::Errors::InvalidParameterValue
  end

  it "can subscribe to a SQS queue" do
    queue = sqs.create_queue(queue_name: "my-queue")
    topic = sns_resource.create_topic(name: "my-topic")
    topic.subscribe(queue, endpoint: "http://localhost:4579", protocol: "sqs")
  end

  it "won't subscribe twice to the same endpoint" do
    queue = sqs.create_queue(queue_name: "my-queue")
    topic = sns_resource.create_topic(name: "my-topic")
    topic.subscribe(queue, endpoint: "http://localhost:4579", protocol: "sqs")
    topic.subscribe(queue, endpoint: "http://localhost:4579", protocol: "sqs")
    expect(sns_resource.subscriptions.to_a.size).to eq 1
  end
end
