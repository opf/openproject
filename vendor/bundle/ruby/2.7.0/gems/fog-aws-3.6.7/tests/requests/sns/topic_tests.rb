Shindo.tests('AWS::SNS | topic lifecycle tests', ['aws', 'sns']) do

  tests('success') do

    tests("#create_topic('fog_topic_tests')").formats(AWS::SNS::Formats::BASIC.merge('TopicArn' => String)) do
      body = Fog::AWS[:sns].create_topic('fog_topic_tests').body
      @topic_arn = body["TopicArn"]
      body
    end

    tests("#list_topics").formats(AWS::SNS::Formats::BASIC.merge('Topics' => [String])) do
      Fog::AWS[:sns].list_topics.body
    end

    tests("#set_topic_attributes('#{@topic_arn}', 'DisplayName', 'other-fog_topic_tests')").formats(AWS::SNS::Formats::BASIC) do
      Fog::AWS[:sns].set_topic_attributes(@topic_arn, 'DisplayName', 'other-fog_topic_tests').body
    end

    get_topic_attributes_format = AWS::SNS::Formats::BASIC.merge({
      'Attributes' => {
        'DisplayName'             => String,
        'Owner'                   => String,
        'Policy'                  => String,
        'SubscriptionsConfirmed'  => Integer,
        'SubscriptionsDeleted'    => Integer,
        'SubscriptionsPending'    => Integer,
        'TopicArn'                => String
      }
    })

    tests("#get_topic_attributes('#{@topic_arn})").formats(get_topic_attributes_format) do
      Fog::AWS[:sns].get_topic_attributes(@topic_arn).body
    end

    tests("#add_permission('#{@topic_arn}')").formats(AWS::SNS::Formats::BASIC) do
      Fog::AWS[:sns].add_permission('TopicArn' => @topic_arn, 'Label' => 'Test', 'ActionName.member.1' => 'Subscribe', 'AWSAccountId.member.1' => '1234567890').body
    end

    tests("#remove_permission('#{@topic_arn}')").formats(AWS::SNS::Formats::BASIC) do
      Fog::AWS[:sns].remove_permission('TopicArn' => @topic_arn, 'Label' => 'Test').body
    end

    tests("#delete_topic('#{@topic_arn}')").formats(AWS::SNS::Formats::BASIC) do
      Fog::AWS[:sns].delete_topic(@topic_arn).body
    end

  end

  tests('failure') do

  end

end
