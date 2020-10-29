Shindo.tests('AWS::SQS | message requests', ['aws']) do

  tests('success') do

    @queue_url = Fog::AWS[:sqs].create_queue('fog_message_tests').body['QueueUrl']

    send_message_format = AWS::SQS::Formats::BASIC.merge({
      'MessageId'         => String,
      'MD5OfMessageBody'  => String
    })

    tests("#send_message('#{@queue_url}', 'message')").formats(send_message_format) do
      Fog::AWS[:sqs].send_message(@queue_url, 'message').body
    end

    receive_message_format = AWS::SQS::Formats::BASIC.merge({
      'Message' => [{
        'Attributes'    => {
          'ApproximateFirstReceiveTimestamp'  => Time,
          'ApproximateReceiveCount'           => Integer,
          'SenderId'                          => String,
          'SentTimestamp'                     => Time
        },
        'Body'          => String,
        'MD5OfBody'     => String,
        'MessageId'     => String,
        'ReceiptHandle' => String
      }]
    })

    tests("#receive_message").formats(receive_message_format) do
      data = Fog::AWS[:sqs].receive_message(@queue_url).body
      @receipt_handle = data['Message'].first['ReceiptHandle']
      data
    end

    tests("#change_message_visibility('#{@queue_url}, '#{@receipt_handle}', 60)").formats(AWS::SQS::Formats::BASIC) do
      Fog::AWS[:sqs].change_message_visibility(@queue_url, @receipt_handle, 60).body
    end

    tests("#delete_message('#{@queue_url}', '#{@receipt_handle}')").formats(AWS::SQS::Formats::BASIC) do
      Fog::AWS[:sqs].delete_message(@queue_url, @receipt_handle).body
    end

    unless Fog.mocking?
      Fog::AWS[:sqs].delete_queue(@queue_url)
    end

  end

end
