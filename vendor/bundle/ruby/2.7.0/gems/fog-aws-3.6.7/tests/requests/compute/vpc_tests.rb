Shindo.tests('Fog::Compute[:aws] | vpc requests', ['aws']) do

  @create_vpcs_format = {
    'vpcSet' => [{
      'vpcId'           => String,
      'state'           => String,
      'cidrBlock'       => String,
      'dhcpOptionsId'   => String,
      'tagSet'          => Hash
    }],
    'requestId' => String
  }

  @describe_vpcs_classic_link_format = {
    'vpcSet' => [{
      'vpcId'              => String,
      'tagSet'             => Hash,
      'classicLinkEnabled' => Fog::Boolean
    }],
    'requestId' => String
  }
  @describe_classic_link_instances = {
    'instancesSet' => [{
      'vpcId'              => String,
      'tagSet'             => Hash,
      'instanceId'         => String,
      'groups'             => [{'groupId' => String, 'groupName' => String}]
    }],
    'requestId' => String,
    'NextToken' => Fog::Nullable::String
  }

  @describe_vpcs_format = {
    'vpcSet' => [{
      'vpcId'                       => String,
      'state'                       => String,
      'cidrBlock'                   => String,
      'dhcpOptionsId'               => String,
      'tagSet'                      => Hash,
      'instanceTenancy'             => Fog::Nullable::String,
      'cidrBlockAssociationSet'     => [{'cidrBlock'     => String, 'associationId' => String, 'state' => String}],
      'ipv6CidrBlockAssociationSet' => [{'ipv6CidrBlock' => String, 'associationId' => String, 'state' => String}]
    }],
    'requestId' => String
  }

  @describe_vpc_classic_link_dns_support_format = {
    "vpcs" => [{
      "vpcId"                   => String,
      "classicLinkDnsSupported" => Fog::Boolean
    }]
  }

  tests('success') do

    @vpc_id = nil

    tests('#create_vpc').formats(@create_vpcs_format) do
      data = Fog::Compute[:aws].create_vpc('10.255.254.0/28').body
      @vpc_id = data['vpcSet'].first['vpcId']
      data
    end

    tests('#create_vpc').formats(@create_vpcs_format) do
      data = Fog::Compute[:aws].create_vpc('10.255.254.0/28',
        {'InstanceTenancy' => 'default'}).body
      @vpc_id = data['vpcSet'].first['vpcId']
      data
    end

    tests("#create_vpc('10.255.254.0/28', {'InstanceTenancy' => 'dedicated'})").returns('dedicated') do
      data = Fog::Compute[:aws].create_vpc('10.255.254.0/28',
        {'InstanceTenancy' => 'dedicated'}).body
      data['vpcSet'].first['instanceTenancy']
    end

    tests('#describe_vpcs').formats(@describe_vpcs_format) do
      Fog::Compute[:aws].describe_vpcs.body
    end

    [ 'enableDnsSupport', 'enableDnsHostnames'].each do |attrib|
      tests("#describe_vpc_attribute('#{@vpc_id}', #{attrib})").returns(@vpc_id) do
        Fog::Compute[:aws].describe_vpc_attribute(@vpc_id, attrib).body['vpcId']
      end
    end

    tests("#modify_vpc_attribute('#{@vpc_id}', {'EnableDnsSupport.Value' => false})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].modify_vpc_attribute(@vpc_id, {'EnableDnsSupport.Value' => false}).body
    end
    tests("#describe_vpc_attribute(#{@vpc_id}, 'enableDnsSupport')").returns(false) do
      Fog::Compute[:aws].describe_vpc_attribute(@vpc_id, 'enableDnsSupport').body["enableDnsSupport"]
    end
    tests("#modify_vpc_attribute('#{@vpc_id}', {'EnableDnsSupport.Value' => true})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].modify_vpc_attribute(@vpc_id, {'EnableDnsSupport.Value' => true}).body
    end
    tests("#describe_vpc_attribute(#{@vpc_id}, 'enableDnsSupport')").returns(true) do
      Fog::Compute[:aws].describe_vpc_attribute(@vpc_id, 'enableDnsSupport').body["enableDnsSupport"]
    end

    tests("#modify_vpc_attribute('#{@vpc_id}', {'EnableDnsHostnames.Value' => true})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].modify_vpc_attribute(@vpc_id, {'EnableDnsHostnames.Value' => true}).body
    end
    tests("#describe_vpc_attribute(#{@vpc_id}, 'enableDnsHostnames')").returns(true) do
      Fog::Compute[:aws].describe_vpc_attribute(@vpc_id, 'enableDnsHostnames').body["enableDnsHostnames"]
    end
    tests("#modify_vpc_attribute('#{@vpc_id}', {'EnableDnsHostnames.Value' => false})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].modify_vpc_attribute(@vpc_id, {'EnableDnsHostnames.Value' => false}).body
    end
    tests("#describe_vpc_attribute(#{@vpc_id}, 'enableDnsHostnames')").returns(false) do
      Fog::Compute[:aws].describe_vpc_attribute(@vpc_id, 'enableDnsHostnames').body["enableDnsHostnames"]
    end

    tests("#modify_vpc_attribute('#{@vpc_id}')").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].modify_vpc_attribute(@vpc_id).body
    end

    tests("#modify_vpc_attribute('#{@vpc_id}', {'EnableDnsSupport.Value' => true, 'EnableDnsHostnames.Value' => true})").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].modify_vpc_attribute(@vpc_id, {'EnableDnsSupport.Value' => true, 'EnableDnsHostnames.Value' => true}).body
    end

    # Create another vpc to test tag filters
    test_tags = {'foo' => 'bar'}
    @another_vpc = Fog::Compute[:aws].vpcs.create :cidr_block => '1.2.3.4/24', :tags => test_tags

    tests("#describe_vpcs('tag-key' => 'foo')").formats(@describe_vpcs_format)do
      body = Fog::Compute[:aws].describe_vpcs('tag-key' => 'foo').body
      tests("returns 1 vpc").returns(1) { body['vpcSet'].size }
      body
    end

    tests("#describe_vpcs('tag-value' => 'bar')").formats(@describe_vpcs_format)do
      body = Fog::Compute[:aws].describe_vpcs('tag-value' => 'bar').body
      tests("returns 1 vpc").returns(1) { body['vpcSet'].size }
      body
    end

    tests("#describe_vpcs('tag:foo' => 'bar')").formats(@describe_vpcs_format)do
      body = Fog::Compute[:aws].describe_vpcs('tag:foo' => 'bar').body
      tests("returns 1 vpc").returns(1) { body['vpcSet'].size }
      body
    end

    tests("describe_vpc_classic_link(:filters => {'tag-key' => 'foo'}").formats(@describe_vpcs_classic_link_format) do
      body = Fog::Compute[:aws].describe_vpc_classic_link(:filters => {'tag-key' => 'foo'}).body
      tests("returns 1 vpc").returns(1) { body['vpcSet'].size }
      body
    end

    tests("enable_vpc_classic_link").returns(true) do
      Fog::Compute[:aws].enable_vpc_classic_link @vpc_id
      body = Fog::Compute[:aws].describe_vpc_classic_link(:vpc_ids => [@vpc_id]).body
      body['vpcSet'].first['classicLinkEnabled']
    end

    @server = Fog::Compute[:aws].servers.create
    @server.wait_for {ready?}

    @group = Fog::Compute[:aws].security_groups.create :name => 'test-group', :description => 'vpc security group'

    tests("attach_classic_link_vpc") do
      Fog::Compute[:aws].attach_classic_link_vpc(@server.id, @vpc_id, [@group.group_id])
    end

    tests('describe_classic_link_instances').formats(@describe_classic_link_instances) do
      Fog::Compute[:aws].describe_classic_link_instances().body
    end

    tests("detach_classic_link_vpc").returns([]) do
      Fog::Compute[:aws].detach_classic_link_vpc(@server.id, @vpc_id)
      Fog::Compute[:aws].describe_classic_link_instances().body['instancesSet']
    end

    tests("enable_vpc_classic_link_dns_support('#{@vpc_id}')").formats(AWS::Compute::Formats::BASIC) do
      body = Fog::Compute[:aws].enable_vpc_classic_link_dns_support(@vpc_id).body
      body
    end

    tests("#describe_vpc_classic_link_dns_support").formats(@describe_vpc_classic_link_dns_support_format) do
      Fog::Compute[:aws].describe_vpc_classic_link_dns_support.body
    end

    tests("#describe_vpc_classic_link_dns_support(:vpc_ids => ['#{@vpc_id}'])").formats(@describe_vpc_classic_link_dns_support_format) do
      body = Fog::Compute[:aws].describe_vpc_classic_link_dns_support(:vpc_ids => [@vpc_id]).body
      returns(1)       { body['vpcs'].count }
      returns(@vpc_id) { body['vpcs'].first['vpcId'] }
      returns(true)    { body['vpcs'].first['classicLinkDnsSupported'] }
      body
    end

    tests("disable_vpc_classic_link_dns_support('#{@vpc_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].disable_vpc_classic_link_dns_support(@vpc_id).body
    end

    tests("#describe_vpc_classic_link_dns_support(:vpc_ids => ['#{@vpc_id}'])").formats(@describe_vpc_classic_link_dns_support_format) do
      body = Fog::Compute[:aws].describe_vpc_classic_link_dns_support(:vpc_ids => [@vpc_id]).body
      returns(1)       { body['vpcs'].count }
      returns(@vpc_id) { body['vpcs'].first['vpcId'] }
      returns(false)   { body['vpcs'].first['classicLinkDnsSupported'] }
      body
    end

    if !Fog.mocking?
      @server.destroy
      @server.wait_for {state == 'terminated'}
    end

    tests("disable_vpc_classic_link").returns(false) do
      Fog::Compute[:aws].disable_vpc_classic_link @vpc_id
      body = Fog::Compute[:aws].describe_vpc_classic_link(:vpc_ids => [@vpc_id]).body
      body['vpcSet'].first['classicLinkEnabled']
    end

    tests("#delete_vpc('#{@vpc_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_vpc(@vpc_id).body
    end

    # Clean up
    Fog::Compute[:aws].delete_tags(@another_vpc.id, test_tags)
    @another_vpc.destroy
    Fog::AWS::Compute::Mock.reset if Fog.mocking?
  end
end
