Shindo.tests("AWS::EFS | mount targets", ["aws", "efs"]) do
  @file_system = Fog::AWS[:efs].file_systems.create(:creation_token => "fogtoken#{rand(999).to_s}")
  @file_system.wait_for { ready? }

  if Fog.mocking?
    vpc = Fog::Compute[:aws].vpcs.create(:cidr_block => "10.0.0.0/16")
    subnet = Fog::Compute[:aws].subnets.create(:vpc_id => vpc.id, :cidr_block => "10.0.1.0/24")
  else
    vpc = Fog::Compute[:aws].vpcs.first
    subnet = vpc.subnets.first
  end

  security_group = Fog::Compute[:aws].security_groups.create(
    :vpc_id      => vpc.id,
    :name        => "fog#{rand(999).to_s}",
    :description => "fog#{rand(999).to_s}"
  )

  mount_target_params = {
    :file_system_id  => @file_system.identity,
    :subnet_id       => subnet.identity,
    :security_groups => [security_group.group_id]
  }

  collection_tests(Fog::AWS[:efs].mount_targets(:file_system_id => @file_system.identity), mount_target_params, true)

  @file_system.wait_for { number_of_mount_targets == 0 }
  @file_system.destroy
  security_group.destroy
end
