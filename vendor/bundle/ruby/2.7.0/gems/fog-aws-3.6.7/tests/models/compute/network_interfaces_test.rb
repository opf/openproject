Shindo.tests("Fog::Compute[:aws] | network_interfaces", ['aws']) do
  @vpc       = Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')
  @subnet    = Fog::Compute[:aws].subnets.create('vpc_id' => @vpc.id, 'cidr_block' => '10.0.10.16/28')
  @subnet_id = @subnet.subnet_id

  collection_tests(Fog::Compute[:aws].network_interfaces,
                   {:description => 'nic_desc', :name => 'nic_name', :subnet_id => @subnet_id},
                   true)

  @subnet.destroy
  @vpc.destroy
end
