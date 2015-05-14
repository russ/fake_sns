ENV["RACK_ENV"] ||= 'test'

require "bundler/setup"
Bundler.setup

require "yaml"
require "verbose_hash_fetch"
require "aws-sdk"
require "pry"
require "fake_sns/test_integration"
require "fake_sqs/test_integration"


Aws.config = {
  region:             "us-east-1",
  access_key_id:      "fake access key",
  secret_access_key:  "fake secret key",
}
ENV['AWS_REGION'] = 'us-east-1'

db = ENV["SNS_DATABASE"]
db = ":memory:" if ENV["SNS_DATABASE"].to_s == ""

puts "Running tests with database stored in #{db}"
puts "\n\e[34mRunning specs with database \e[33m#{db}\e[0m"

$fake_sns = FakeSNS::TestIntegration.new(database: db, sns_endpoint: "localhost", sns_port: 9293)
$fake_sqs = FakeSQS::TestIntegration.new(database: ":memory:", sqs_endpoint: "localhost", sqs_port: 4569)

module SpecHelper
  def sns
    Aws::SNS::Client.new(endpoint: "http://localhost:9293")
  end

  def sns_resource
    Aws::SNS::Resource.new(client: sns)
  end

  def sqs
    Aws::SQS::Client.new(endpoint: "http://localhost:4569")
  end
end

RSpec.configure do |config|

  config.disable_monkey_patching!

  config.before(:each) { $fake_sns.start }
  config.after(:suite) { $fake_sns.stop }
  config.include SpecHelper

  config.before(:each, :sqs) { $fake_sqs.start }
  config.after(:suite) { $fake_sqs.stop }

end
