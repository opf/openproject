Shindo.tests('AWS::Elasticache | subnet group', ['aws', 'elasticache']) do
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
  @subnets = (1..3).map do
    result = Fog::Compute[:aws].create_subnet(@vpc.id, "10.#{vpc_range}.#{subnet_range}.0/24",
                                              'AvailabilityZone' => subnet_az)
    subnet = result.body['subnet']
    subnet_az = subnet_az.succ
    subnet_range *= 2
    subnet
  end

  tests('success') do
    group_name = 'fog-test'
    description = 'Fog Test'
    subnet_ids = @subnets.map { |sn| sn['subnetId'] }.to_a

    model_tests(
      Fog::AWS[:elasticache].subnet_groups,
      {:name => group_name, :subnet_ids => subnet_ids, :description => description}, true
    )

    collection_tests(
      Fog::AWS[:elasticache].subnet_groups,
      {:name => group_name, :subnet_ids => subnet_ids, :description => description}, true
    )
  end

  @subnets.each do |sn|
    Fog::Compute[:aws].delete_subnet(sn['subnetId'])
  end
  @vpc.destroy
end
