Shindo.tests("AWS::EFS | mount target", ["aws", "efs"]) do
  @file_system = Fog::AWS[:efs].file_systems.create(:creation_token => "fogtoken#{rand(999).to_s}")
  @file_system.wait_for { ready? }

  if Fog.mocking?
    vpc = Fog::Compute[:aws].vpcs.create(:cidr_block => "10.0.0.0/16")
    subnet = Fog::Compute[:aws].subnets.create(:vpc_id => vpc.id, :cidr_block => "10.0.1.0/24")
    default_security_group_data = Fog::Compute[:aws].data[:security_groups].values.find do |sg|
      sg['groupDescription'] == 'default_elb security group'
    end
    default_security_group = Fog::Compute[:aws].security_groups.new(default_security_group_data)
  else
    vpc = Fog::Compute[:aws].vpcs.first
    subnet = vpc.subnets.first
    default_security_group = Fog::Compute[:aws].security_groups.detect { |sg| sg.description == 'default VPC security group' }
  end

  security_group = Fog::Compute[:aws].security_groups.create(
    :vpc_id      => vpc.id,
    :name        => "fog#{rand(999).to_s}",
    :description => "fog#{rand(999).to_s}"
  )

  mount_target_params = {
    :file_system_id  => @file_system.identity,
    :subnet_id       => subnet.identity,
  }

  model_tests(Fog::AWS[:efs].mount_targets, mount_target_params, true) do
    @instance.wait_for { ready? }

    tests("#security_groups") do
      returns([default_security_group.group_id]) { @instance.security_groups }
    end

    tests("#security_groups=") do
      @instance.security_groups = [security_group.group_id]
      returns([security_group.group_id]) { @instance.security_groups }
    end
  end

  @file_system.wait_for { number_of_mount_targets == 0 }
  @file_system.destroy
  security_group.destroy
end
