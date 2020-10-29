Shindo.tests('AWS::AutoScaling | describe types requests', ['aws', 'auto_scaling']) do

  tests('success') do

    tests("#describe_adjustment_types").formats(AWS::AutoScaling::Formats::DESCRIBE_ADJUSTMENT_TYPES) do
      body = Fog::AWS[:auto_scaling].describe_adjustment_types.body

      [ 'ChangeInCapacity',
        'ExactCapacity',
        'PercentChangeInCapacity'
      ].each do |v|
        returns(true, "AdjustmentTypes contains #{v}") do
          body['DescribeAdjustmentTypesResult']['AdjustmentTypes'].any? {|t| t['AdjustmentType'] == v}
        end
      end

      body
    end

    tests("#describe_auto_scaling_notification_types").formats(AWS::AutoScaling::Formats::DESCRIBE_AUTO_SCALING_NOTIFICATION_TYPES) do
      body = Fog::AWS[:auto_scaling].describe_auto_scaling_notification_types.body

      [ 'autoscaling:EC2_INSTANCE_LAUNCH',
        'autoscaling:EC2_INSTANCE_LAUNCH_ERROR',
        'autoscaling:EC2_INSTANCE_TERMINATE',
        'autoscaling:EC2_INSTANCE_TERMINATE_ERROR',
        'autoscaling:TEST_NOTIFICATION'
      ].each do |v|
        returns(true, "AutoScalingNotificationTypes contains #{v}") do
          body['DescribeAutoScalingNotificationTypesResult']['AutoScalingNotificationTypes'].include?(v)
        end
      end

      body
    end

    tests("#describe_metric_collection_types").formats(AWS::AutoScaling::Formats::DESCRIBE_METRIC_COLLECTION_TYPES) do
      body = Fog::AWS[:auto_scaling].describe_metric_collection_types.body

      [ 'GroupDesiredCapacity',
        'GroupInServiceInstances',
        'GroupMaxSize',
        'GroupMinSize',
        'GroupPendingInstances',
        'GroupTerminatingInstances',
        'GroupTotalInstances'
      ].each do |v|
        returns(true, "Metrics contains #{v}") do
          body['DescribeMetricCollectionTypesResult']['Metrics'].any? {|t| t['Metric'] == v}
        end
      end

      [ '1Minute'
      ].each do |v|
        returns(true, "Granularities contains #{v}") do
          body['DescribeMetricCollectionTypesResult']['Granularities'].any? {|t| t['Granularity'] == v}
        end
      end

      body
    end

    tests("#describe_scaling_process_types").formats(AWS::AutoScaling::Formats::DESCRIBE_SCALING_PROCESS_TYPES) do
      body = Fog::AWS[:auto_scaling].describe_scaling_process_types.body

      [ 'AZRebalance',
        'AddToLoadBalancer',
        'AlarmNotification',
        'HealthCheck',
        'Launch',
        'ReplaceUnhealthy',
        'ScheduledActions',
        'Terminate'
      ].each do |v|
        returns(true, "Processes contains #{v}") do
          body['DescribeScalingProcessTypesResult']['Processes'].any? {|t| t['ProcessName'] == v}
        end
      end

      body
    end

    tests("#describe_termination_policy_types").formats(AWS::AutoScaling::Formats::DESCRIBE_TERMINATION_POLICY_TYPES) do
      body = Fog::AWS[:auto_scaling].describe_termination_policy_types.body

      [ 'ClosestToNextInstanceHour',
        'Default',
        'NewestInstance',
        'OldestInstance',
        'OldestLaunchConfiguration'
      ].each do |v|
        returns(true, "TerminationPolicyTypes contains #{v}") do
          body['DescribeTerminationPolicyTypesResult']['TerminationPolicyTypes'].include?(v)
        end
      end

      body
    end

  end

end
