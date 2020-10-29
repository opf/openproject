Shindo.tests("Fog::Compute[:aws] | subnet", ['aws']) do
  @vpc=Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')
  model_tests(Fog::Compute[:aws].subnets, {:vpc_id => @vpc.id, :cidr_block => '10.0.10.0/28', :availability_zone => 'us-east-1b'}, true) do
    @ni = Fog::Compute[:aws].network_interfaces.create(:description => 'fog eni', :name => uniq_id('fog-eni'), :subnet_id => @instance.identity)

    tests("#network_interfaces") do
      returns([@ni]) { @instance.network_interfaces.to_a }
    end

    @ni.destroy
  end
  @vpc.destroy
end
