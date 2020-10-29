Shindo.tests("Fog::Compute[:aws] | network_acl", ['aws']) do
  @vpc    = Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')
  @subnet = Fog::Compute[:aws].subnets.create('vpc_id' => @vpc.id, 'cidr_block' => '10.0.10.16/28')

  model_tests(Fog::Compute[:aws].network_acls, { :vpc_id => @vpc.id }, true)

  tests("associate_with") do
    @new_nacl     = Fog::Compute[:aws].network_acls.create(:vpc_id => @vpc.id)
    @default_nacl = Fog::Compute[:aws].network_acls.all('vpc-id' => @vpc.id, 'default' => true).first

    test("associate_with new_nacl") do
      @new_nacl.associate_with(@subnet)
    end

    @new_nacl.reload

    test("associate_with correctly updates new_nacl") do
      @new_nacl.associations.map { |a| a['subnetId'] } == [@subnet.subnet_id]
    end

    @default_nacl.associate_with(@subnet)
    @new_nacl.reload
    @default_nacl.reload

    test("associate_with correctly updates new_nacl after removal") do
      @new_nacl.associations.map { |a| a['subnetId'] } == []
    end

    test("associate_with correctly updates default_nacl after removal") do
      @default_nacl.associations.map { |a| a['subnetId'] } == [@subnet.subnet_id]
    end

    @new_nacl.destroy
  end

  tests("add_rule and remove_rule") do
    @new_nacl = Fog::Compute[:aws].network_acls.create(:vpc_id => @vpc.id)
    default_rules = @new_nacl.entries.dup

    test("add a new inbound rule") do
      @new_nacl.add_inbound_rule(100, Fog::AWS::Compute::NetworkAcl::TCP, 'allow', '0.0.0.0/0', 'PortRange.From' => 22, 'PortRange.To' => 22)
      @new_nacl.reload
      (@new_nacl.entries - default_rules) == [{
        "icmpTypeCode" => {},
        "portRange"    => {
          "from"       => 22,
          "to"         => 22
        },
        "ruleNumber"   => 100,
        "protocol"     => 6,
        "ruleAction"   => "allow",
        "egress"       => false,
        "cidrBlock"    => "0.0.0.0/0"
      }]
    end

    test("remove inbound rule") do
      @new_nacl.remove_inbound_rule(100)
      @new_nacl.reload
      @new_nacl.entries == default_rules
    end

    test("add a new outbound rule") do
      @new_nacl.add_outbound_rule(100, Fog::AWS::Compute::NetworkAcl::TCP, 'allow', '0.0.0.0/0', 'PortRange.From' => 22, 'PortRange.To' => 22)
      @new_nacl.reload
      (@new_nacl.entries - default_rules) == [{
        "icmpTypeCode" => {},
        "portRange"    => {
          "from"       => 22,
          "to"         => 22
        },
        "ruleNumber"   => 100,
        "protocol"     => 6,
        "ruleAction"   => "allow",
        "egress"       => true,
        "cidrBlock"    => "0.0.0.0/0"
      }]
    end

    test("remove outbound rule") do
      @new_nacl.remove_outbound_rule(100)
      @new_nacl.reload
      @new_nacl.entries == default_rules
    end

    test("update rule") do
      @new_nacl.add_inbound_rule(100, Fog::AWS::Compute::NetworkAcl::TCP, 'allow', '0.0.0.0/0', 'PortRange.From' => 22, 'PortRange.To' => 22)
      @new_nacl.update_inbound_rule(100, Fog::AWS::Compute::NetworkAcl::TCP, 'allow', '10.0.0.0/8', 'PortRange.From' => 22, 'PortRange.To' => 22)
      @new_nacl.reload
      (@new_nacl.entries - default_rules) == [{
        "icmpTypeCode" => {},
        "portRange"    => {
          "from"       => 22,
          "to"         => 22
        },
        "ruleNumber"   => 100,
        "protocol"     => 6,
        "ruleAction"   => "allow",
        "egress"       => false,
        "cidrBlock"    => "10.0.0.0/8"
      }]
    end

    @new_nacl.destroy
  end

  @subnet.destroy
  @vpc.destroy
end
