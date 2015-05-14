RSpec.describe "Topics" do

  it "rejects invalid characters in topic names" do
    expect {
      sns_resource.create_topic(name: "dot.dot")
    }.to raise_error(Aws::SNS::Errors::InvalidParameterValue)
  end

  it "creates a new topic" do
    topic = sns_resource.create_topic(name: "my-topic")
    expect(topic.arn).to match(/arn:aws:sns:us-east-1:(\w+):my-topic/)

    new_topic = sns_resource.create_topic(name: "other-topic")
    expect(new_topic.arn).not_to eq(topic.arn)

    existing_topic = sns_resource.create_topic(name: "my-topic")
    expect(existing_topic.arn).to eq(topic.arn)
  end

  it "lists topics" do
    topic1 = sns_resource.create_topic(name: "my-topic-1")
    topic2 = sns_resource.create_topic(name: "my-topic-2")

    expect(sns_resource.topics.map(&:arn)).to match_array([topic1.arn, topic2.arn])
  end

  it "deletes topics" do
    topic = sns_resource.create_topic(name: "my-topic")
    expect(sns_resource.topics.map(&:arn)).to eq([topic.arn])
    topic.delete
    expect(sns_resource.topics.map(&:arn)).to eq([])
  end

  it "can set and read attributes" do
    topic = sns_resource.create_topic(name: "my-topic")
    topic.set_attributes(attribute_name: "DisplayName", attribute_value: "the display name")
    expect(topic.attributes["DisplayName"]).to eq("the display name")
  end
end
