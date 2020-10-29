Shindo.tests('AWS::AutoScaling | notification configuration requests', ['aws', 'auto_scaling']) do

  image_id = {  # Ubuntu 12.04 LTS 64-bit EBS
    'ap-northeast-1' => 'ami-60c77761',
    'ap-southeast-1' => 'ami-a4ca8df6',
    'ap-southeast-2' => 'ami-fb8611c1',
    'eu-west-1'      => 'ami-e1e8d395',
    'sa-east-1'      => 'ami-8cd80691',
    'us-east-1'      => 'ami-a29943cb',
    'us-west-1'      => 'ami-87712ac2',
    'us-west-2'      => 'ami-20800c10'
  }

  now = Time.now.utc.to_i
  lc_name = "fog-test-#{now}"
  asg_name = "fog-test-#{now}"

  topic_name = "fog-test-#{now}"
  begin
    topic = Fog::AWS[:sns].create_topic(topic_name).body
    topic_arn = topic['TopicArn']
  rescue Fog::Errors::MockNotImplemented
    topic_arn = Fog::AWS::Mock.arn('sns', Fog::AWS[:auto_scaling].data[:owner_id], "fog-test-#{now}", Fog::AWS[:auto_scaling].region)
  end

  lc = Fog::AWS[:auto_scaling].create_launch_configuration(image_id[Fog::AWS[:auto_scaling].region], 't1.micro', lc_name)
  asg = Fog::AWS[:auto_scaling].create_auto_scaling_group(asg_name, "#{Fog::AWS[:auto_scaling].region}a", lc_name, 0, 0)

  tests('raises') do
    tests("#put_notification_configuration(non-existent-group)").raises(Fog::AWS::AutoScaling::ValidationError) do
      Fog::AWS[:auto_scaling].put_notification_configuration('fog-test-nonexistent-group', 'autoscaling:TEST_NOTIFICATION', topic_arn)
    end

    tests("#put_notification_configuration(null-types)").raises(Fog::AWS::AutoScaling::ValidationError) do
      Fog::AWS[:auto_scaling].put_notification_configuration(asg_name, [], topic_arn)
    end
  end

  tests('success') do
    tests("#put_notification_configuration(string)").formats(AWS::AutoScaling::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:auto_scaling].put_notification_configuration(asg_name, 'autoscaling:TEST_NOTIFICATION', topic_arn).body
    end

    tests("#describe_notification_configurations").formats(AWS::AutoScaling::Formats::DESCRIBE_NOTIFICATION_CONFIGURATIONS) do
      pending if Fog.mocking?
      body = Fog::AWS[:auto_scaling].describe_notification_configurations('AutoScalingGroupNames' => asg_name).body
      notification_configurations = body['DescribeNotificationConfigurationsResult']['NotificationConfigurations']
      returns(true, 'exactly 1 configurations') do
        notification_configurations.size == 1
      end
      returns(true) do
        config = notification_configurations.first
        config['AutoScalingGroupName'] == asg_name && config['TopicARN'] == topic_arn && config['NotificationType'] == 'autoscaling:TEST_NOTIFICATION'
      end
      body
    end

    tests("#put_notification_configuration(array)").formats(AWS::AutoScaling::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:auto_scaling].put_notification_configuration(asg_name, ['autoscaling:EC2_INSTANCE_LAUNCH', 'autoscaling:EC2_INSTANCE_TERMINATE'], topic_arn).body
    end

    tests("#describe_notification_configurations").formats(AWS::AutoScaling::Formats::DESCRIBE_NOTIFICATION_CONFIGURATIONS) do
      pending if Fog.mocking?
      body = Fog::AWS[:auto_scaling].describe_notification_configurations('AutoScalingGroupName' => asg_name).body
      notification_configurations = body['DescribeNotificationConfigurationsResult']['NotificationConfigurations']
      returns(true, 'exactly 2 configurations') do
        notification_configurations.size == 2
      end
      [ 'autoscaling:EC2_INSTANCE_LAUNCH', 'autoscaling:EC2_INSTANCE_TERMINATE'].each do |type|
        returns(true) do
          notification_configurations.any? do |config|
            config['AutoScalingGroupName'] == asg_name && config['TopicARN'] == topic_arn && config['NotificationType'] == type
          end
        end
      end
      body
    end

    tests("#describe_notification_configurations(all)").formats(AWS::AutoScaling::Formats::DESCRIBE_NOTIFICATION_CONFIGURATIONS) do
      pending if Fog.mocking?
      body = Fog::AWS[:auto_scaling].describe_notification_configurations().body
      notification_configurations = body['DescribeNotificationConfigurationsResult']['NotificationConfigurations']
      returns(true, 'at least 2 configurations') do
        notification_configurations.size >= 2
      end
      [ 'autoscaling:EC2_INSTANCE_LAUNCH', 'autoscaling:EC2_INSTANCE_TERMINATE'].each do |type|
        returns(true) do
          notification_configurations.any? do |config|
            config['AutoScalingGroupName'] == asg_name && config['TopicARN'] == topic_arn && config['NotificationType'] == type
          end
        end
      end

      body
    end

    tests("#delete_notification_configuration").formats(AWS::AutoScaling::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:auto_scaling].delete_notification_configuration(asg_name, topic_arn).body
    end

    tests("#describe_notification_configurations").formats(AWS::AutoScaling::Formats::DESCRIBE_NOTIFICATION_CONFIGURATIONS) do
      pending if Fog.mocking?
      body = Fog::AWS[:auto_scaling].describe_notification_configurations('AutoScalingGroupNames' => asg_name).body
      returns(true) do
        body['DescribeNotificationConfigurationsResult']['NotificationConfigurations'].empty?
      end
      body
    end
  end

  Fog::AWS[:auto_scaling].delete_auto_scaling_group(asg_name)
  Fog::AWS[:auto_scaling].delete_launch_configuration(lc_name)

  if topic
    begin
      Fog::AWS[:sns].delete_topic(topic_arn)
    rescue Fog::Errors::MockNotImplemented
    end
  end

end
