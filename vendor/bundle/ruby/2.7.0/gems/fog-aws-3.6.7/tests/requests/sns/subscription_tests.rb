Shindo.tests('AWS::SES | topic lifecycle tests', ['aws', 'sns']) do

  unless Fog.mocking?
    @topic_arn = Fog::AWS[:sns].create_topic('fog_subscription_tests').body['TopicArn']
    @queue_url = Fog::AWS[:sqs].create_queue('fog_subscription_tests').body['QueueUrl']
    @queue_arn = Fog::AWS[:sqs].get_queue_attributes(@queue_url, 'QueueArn').body['Attributes']['QueueArn']
    Fog::AWS[:sqs].set_queue_attributes(
      @queue_url,
      'Policy',
      Fog::JSON.encode({
        'Id' => @topic_arn,
        'Statement' => {
          'Action'    => 'sqs:SendMessage',
          'Condition' => {
            'StringEquals' => { 'aws:SourceArn' => @topic_arn }
          },
          'Effect'    => 'Allow',
          'Principal' => { 'AWS' => '*' },
          'Resource'  => @queue_arn,
          'Sid'       => "#{@topic_arn}+sqs:SendMessage"
        },
        'Version' => '2008-10-17'
      })
    )
  end

  tests('success') do

    tests("#subscribe('#{@topic_arn}', '#{@queue_arn}', 'sqs')").formats(AWS::SNS::Formats::BASIC.merge('SubscriptionArn' => String)) do
      pending if Fog.mocking?
      body = Fog::AWS[:sns].subscribe(@topic_arn, @queue_arn, 'sqs').body
      @subscription_arn = body['SubscriptionArn']
      body
    end

    list_subscriptions_format = AWS::SNS::Formats::BASIC.merge({
      'Subscriptions' => [{
        'Endpoint'        => String,
        'Owner'           => String,
        'Protocol'        => String,
        'SubscriptionArn' => String,
        'TopicArn'        => String
      }]
    })

    tests("#list_subscriptions").formats(list_subscriptions_format) do
      pending if Fog.mocking?
      Fog::AWS[:sns].list_subscriptions.body
    end

    tests("#list_subscriptions_by_topic('#{@topic_arn}')").formats(list_subscriptions_format) do
      pending if Fog.mocking?
      body = Fog::AWS[:sns].list_subscriptions_by_topic(@topic_arn).body
    end

    tests("#publish('#{@topic_arn}', 'message')").formats(AWS::SNS::Formats::BASIC.merge('MessageId' => String)) do
      pending if Fog.mocking?
      body = Fog::AWS[:sns].publish(@topic_arn, 'message').body
    end

    tests("#receive_message('#{@queue_url}')...").returns('message') do
      pending if Fog.mocking?
      message = nil
      Fog.wait_for do
        message = Fog::AWS[:sqs].receive_message(@queue_url).body['Message'].first
      end
      Fog::JSON.decode(message['Body'])['Message']
    end

    tests("#unsubscribe('#{@subscription_arn}')").formats(AWS::SNS::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:sns].unsubscribe(@subscription_arn).body
    end

  end

  tests('failure') do

  end

  unless Fog.mocking?
    Fog::AWS[:sns].delete_topic(@topic_arn)
    Fog::AWS[:sqs].delete_queue(@queue_url)
  end

end
