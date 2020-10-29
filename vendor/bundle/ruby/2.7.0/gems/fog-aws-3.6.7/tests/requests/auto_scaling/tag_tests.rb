Shindo.tests('AWS::AutoScaling | tag requests', ['aws', 'auto_scaling']) do

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

  asg_tag = {
    'Key'               => 'Name',
    'PropagateAtLaunch' => true,
    'ResourceId'        => asg_name,
    'ResourceType'      => 'auto-scaling-group',
    'Value'             => asg_name
  }

  Fog::AWS[:auto_scaling].create_launch_configuration(image_id[Fog::AWS[:auto_scaling].region], 't1.micro', lc_name)
  Fog::AWS[:auto_scaling].create_auto_scaling_group(asg_name, "#{Fog::AWS[:auto_scaling].region}a", lc_name, 0, 0, 'Tags' => [asg_tag])

  tests('raises') do
    tests("#create_or_update_tags(empty)").raises(Fog::AWS::AutoScaling::ValidationError) do
      Fog::AWS[:auto_scaling].create_or_update_tags([])
    end

    tests("#delete_tags(empty)").raises(Fog::AWS::AutoScaling::ValidationError) do
      Fog::AWS[:auto_scaling].delete_tags([])
    end
  end

  tests('success') do
    tests("#describe_auto_scaling_groups(#{asg_name}").formats(AWS::AutoScaling::Formats::DESCRIBE_AUTO_SCALING_GROUPS) do
      body = Fog::AWS[:auto_scaling].describe_auto_scaling_groups('AutoScalingGroupNames' => asg_name).body
      auto_scaling_group = body['DescribeAutoScalingGroupsResult']['AutoScalingGroups'].first
      returns(true) { auto_scaling_group.key?('Tags') }
      returns(true) { auto_scaling_group['Tags'].size == 1 }
      returns(true) { auto_scaling_group['Tags'].first == asg_tag }
      body
    end

    tests("#describe_tags").formats(AWS::AutoScaling::Formats::DESCRIBE_TAGS) do
      pending if Fog.mocking?
      body = Fog::AWS[:auto_scaling].describe_tags.body
      tags = body['DescribeTagsResult']['Tags']
      returns(true) { tags.any? {|tag| tag == asg_tag} }
      body
    end

    # TODO: more tests!
  end

  Fog::AWS[:auto_scaling].delete_auto_scaling_group(asg_name)
  Fog::AWS[:auto_scaling].delete_launch_configuration(lc_name)

end
