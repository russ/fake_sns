module FakeSNS
  module Actions
    class Subscribe < Action

      param endpoint: "Endpoint"
      param protocol: "Protocol"
      param topic_arn: "TopicArn"
      param account_id: "account_id"

      attr_reader :topic

      def call
        @topic = db.topics.fetch(topic_arn) do
          raise InvalidParameterValue, "Unknown topic: #{topic_arn}"
        end
        @subscription = (existing_subscription || new_subscription)
      end

      def subscription_arn
        @subscription["arn"]
      end

      private

      def existing_subscription
        db.subscriptions.to_a.find { |s|
          s.topic_arn == topic_arn && s.endpoint == endpoint
        }
      end

      def new_subscription
        attributes = {
          "arn"       => "#{topic_arn}:#{account_id}",
          "protocol"  => protocol,
          "endpoint"  => endpoint,
          "topic_arn" => topic_arn,
        }
        db.subscriptions.create(attributes)
        attributes
      end

    end
  end
end
