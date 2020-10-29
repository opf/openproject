Shindo.tests('AWS::ELBV2 | load_balancer_tests', ['aws', 'elb']) do
  @load_balancer_id = 'fog-test-elb'
  @key_name = 'fog-test'
  vpc = Fog::Compute[:aws].create_vpc('10.255.254.64/28').body['vpcSet'].first
  @subnet_id = Fog::Compute[:aws].create_subnet(vpc['vpcId'], vpc['cidrBlock']).body['subnet']['subnetId']
  @tags = { 'test1' => 'Value1', 'test2' => 'Value2' }

  tests('success') do
    tests('#create_load_balancer').formats(AWS::ELBV2::Formats::CREATE_LOAD_BALANCER) do
      options = {
        subnets: [@subnet_id]
      }
      load_balancer = Fog::AWS[:elbv2].create_load_balancer(@load_balancer_id, options).body
      @load_balancer_arn = load_balancer['CreateLoadBalancerResult']['LoadBalancers'].first['LoadBalancerArn']
      load_balancer
    end

    tests('#describe_load_balancers').formats(AWS::ELBV2::Formats::DESCRIBE_LOAD_BALANCERS) do
      Fog::AWS[:elbv2].describe_load_balancers.body
    end

    tests('#describe_load_balancers with bad name') do
      raises(Fog::AWS::ELBV2::NotFound) { Fog::AWS[:elbv2].describe_load_balancers('LoadBalancerNames' => 'none-such-lb') }
    end

    tests("#add_tags('#{@load_balancer_arn}', #{@tags})").formats(AWS::ELBV2::Formats::BASIC) do
      Fog::AWS[:elbv2].add_tags(@load_balancer_arn, @tags).body
    end

    tests('#describe_tags').formats(AWS::ELBV2::Formats::DESCRIBE_TAGS) do
      Fog::AWS[:elbv2].describe_tags(@load_balancer_arn).body
    end

    tests('#describe_tags with at least one wrong arn') do
      raises(Fog::AWS::ELBV2::NotFound) { Fog::AWS[:elbv2].describe_tags([@load_balancer_arn, 'wrong_arn']) }
    end

    tests("#describe_tags(#{@load_balancer_arn})").returns(@tags) do
     Fog::AWS[:elbv2].describe_tags(@load_balancer_arn).body['DescribeTagsResult']['TagDescriptions'].first['Tags']
    end

    tests("#remove_tags('#{@load_balancer_arn}', #{@tags.keys})").formats(AWS::ELBV2::Formats::BASIC) do
      Fog::AWS[:elbv2].remove_tags(@load_balancer_arn, @tags.keys).body
    end

    tests("#describe_tags(#{@load_balancer_arn})").returns({}) do
      Fog::AWS[:elbv2].describe_tags(@load_balancer_arn).body['DescribeTagsResult']['TagDescriptions'].first['Tags']
    end
  end
end
