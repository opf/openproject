Shindo.tests('AWS::SQS | queue requests', ['aws']) do

  tests('success') do

    create_queue_format = AWS::SQS::Formats::BASIC.merge({
      'QueueUrl' => String
    })

    tests("#create_queue('fog_queue_tests')").formats(create_queue_format) do
      data = Fog::AWS[:sqs].create_queue('fog_queue_tests').body
      @queue_url = data['QueueUrl']
      data
    end

    list_queues_format = AWS::SQS::Formats::BASIC.merge({
      'QueueUrls' => [String]
    })

    tests("#list_queues").formats(list_queues_format) do
      Fog::AWS[:sqs].list_queues.body
    end

    tests("#set_queue_attributes('#{@queue_url}', 'VisibilityTimeout', 60)").formats(AWS::SQS::Formats::BASIC) do
      Fog::AWS[:sqs].set_queue_attributes(@queue_url, 'VisibilityTimeout', 60).body
    end

    get_queue_attributes_format = AWS::SQS::Formats::BASIC.merge({
      'Attributes' => {
        'ApproximateNumberOfMessages'           => Integer,
        'ApproximateNumberOfMessagesNotVisible' => Integer,
        'CreatedTimestamp'                      => Time,
        'MaximumMessageSize'                    => Integer,
        'LastModifiedTimestamp'                 => Time,
        'MessageRetentionPeriod'                => Integer,
        'QueueArn'                              => String,
        'VisibilityTimeout'                     => Integer
      }
    })

    tests("#get_queue_attributes('#{@queue_url}', 'All')").formats(get_queue_attributes_format) do
      Fog::AWS[:sqs].get_queue_attributes(@queue_url, 'All').body
    end

    tests("#delete_queue('#{@queue_url}')").formats(AWS::SQS::Formats::BASIC) do
      Fog::AWS[:sqs].delete_queue(@queue_url).body
    end

  end

end
