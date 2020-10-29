Shindo.tests('AWS::RDS | event subscription requests', ['aws', 'rds']) do
  pending unless Fog.mocking?

  @name = 'fog'
  @arn  = 'arn:aws:sns:us-east-1:12345678910:fog'

  tests('success') do
    tests('#create_event_subscription').formats(AWS::RDS::Formats::CREATE_EVENT_SUBSCRIPTION) do
      body = Fog::AWS[:rds].create_event_subscription('SubscriptionName' => @name, 'SnsTopicArn' => @arn).body

      returns(@name) { body['CreateEventSubscriptionResult']['EventSubscription']['CustSubscriptionId'] }
      returns('creating') { body['CreateEventSubscriptionResult']['EventSubscription']['Status'] }
      body
    end

    tests("#describe_event_subscriptions").formats(AWS::RDS::Formats::DESCRIBE_EVENT_SUBSCRIPTIONS) do
      returns('active') { Fog::AWS[:rds].describe_event_subscriptions.body['DescribeEventSubscriptionsResult']['EventSubscriptionsList'].first['Status'] }
      Fog::AWS[:rds].describe_event_subscriptions.body
    end

    tests("#delete_event_subscription").formats(AWS::RDS::Formats::BASIC) do
      body = Fog::AWS[:rds].delete_event_subscription(@name).body

      returns('deleting') { Fog::AWS[:rds].describe_event_subscriptions('SubscriptionName' => @name).body['DescribeEventSubscriptionsResult']['EventSubscriptionsList'].first['Status'] }
      raises(Fog::AWS::RDS::NotFound) { Fog::AWS[:rds].describe_event_subscriptions('SubscriptionName' => @name) }

      body
    end
  end
end
