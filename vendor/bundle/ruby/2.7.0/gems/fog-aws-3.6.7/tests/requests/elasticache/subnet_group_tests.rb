Shindo.tests('AWS::Elasticache | subnet group requests', ['aws', 'elasticache']) do
  # random_differentiator
  # Useful when rapidly re-running tests, so we don't have to wait
  # serveral minutes for deleted VPCs/subnets to disappear
  suffix = rand(65536).to_s(16)
  @subnet_group_name = "fog-test-#{suffix}"

  vpc_range = rand(245) + 10
  @vpc = Fog::Compute[:aws].vpcs.create('cidr_block' => "10.#{vpc_range}.0.0/16")

  # Create 4 subnets in this VPC, each one in a different AZ
  subnet_az = 'us-east-1a'
  subnet_range = 8
  @subnets = (1..4).map do
    subnet = Fog::Compute[:aws].create_subnet(@vpc.id, "10.#{vpc_range}.#{subnet_range}.0/24",
      'AvailabilityZone' => subnet_az).body['subnet']
    subnet_az = subnet_az.succ
    subnet_range *= 2
    subnet
  end

  tests('success') do

    subnet_ids = @subnets.map { |sn| sn['subnetId'] }.to_a

    tests("#create_cache_subnet_group").formats(AWS::Elasticache::Formats::CREATE_CACHE_SUBNET_GROUP) do
      result = Fog::AWS[:elasticache].create_cache_subnet_group(@subnet_group_name, subnet_ids, 'A subnet group').body

      returns(@subnet_group_name) { result['CreateCacheSubnetGroupResult']['CacheSubnetGroup']['CacheSubnetGroupName'] }
      returns('A subnet group') { result['CreateCacheSubnetGroupResult']['CacheSubnetGroup']['CacheSubnetGroupDescription'] }
      returns(@vpc.id) { result['CreateCacheSubnetGroupResult']['CacheSubnetGroup']['VpcId'] }
      returns(subnet_ids.sort) { result['CreateCacheSubnetGroupResult']['CacheSubnetGroup']['Subnets'].sort }

      result
    end

    tests("#describe_cache_subnet_groups").formats(AWS::Elasticache::Formats::DESCRIBE_CACHE_SUBNET_GROUPS) do
      Fog::AWS[:elasticache].describe_cache_subnet_groups.body
    end

    tests("#delete_cache_subnet_group").formats(AWS::Elasticache::Formats::BASIC) do
      Fog::AWS[:elasticache].delete_cache_subnet_group(@subnet_group_name).body
    end

  end

  @subnets.each do |sn|
    Fog::Compute[:aws].delete_subnet(sn['subnetId'])
  end
  @vpc.destroy

end
