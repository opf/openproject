Shindo.tests('Fog::Compute[:aws] | network acl requests', ['aws']) do

  @network_acl_format = {
    'networkAclId'   => String,
    'vpcId'          => String,
    'default'        => Fog::Boolean,
    'entrySet'       => [{
      'ruleNumber'   => Integer,
      'protocol'     => Integer,
      'ruleAction'   => String,
      'egress'       => Fog::Boolean,
      'cidrBlock'    => String,
      'icmpTypeCode' => {
        'code'       => Fog::Nullable::Integer,
        'type'       => Fog::Nullable::Integer
      },
      'portRange' => {
        'from'       => Fog::Nullable::Integer,
        'to'         => Fog::Nullable::Integer
      }
    }],
    'associationSet' => Array,
    'tagSet'         => Hash
  }

  @network_acls_format = {
    'requestId'     => String,
    'networkAclSet' => [ @network_acl_format ]
  }

  @network_acl_replace_association = {
    'requestId'        => String,
    'newAssociationId' => String
  }

  tests('success') do
    Fog::AWS::Compute::Mock.reset if Fog.mocking?

    @vpc         = Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')
    @subnet      = Fog::Compute[:aws].subnets.create('vpc_id' => @vpc.id, 'cidr_block' => '10.0.10.16/28')
    @network_acl = nil

    # Describe network interfaces
    tests('#describe_network_acls').formats(@network_acls_format) do
      Fog::Compute[:aws].describe_network_acls.body
    end

    tests('#create_network_acl').formats(@network_acl_format) do
      data = Fog::Compute[:aws].create_network_acl(@vpc.id).body

      @network_acl = data['networkAcl']
      data['networkAcl']
    end

    tests("#create_network_acl_entry").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].create_network_acl_entry(@network_acl['networkAclId'], 100, 6, 'allow', '0.0.0.0/8', false, 'PortRange.From' => 22, 'PortRange.To' => 22).body
    end

    tests("#replace_network_acl_entry").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].replace_network_acl_entry(@network_acl['networkAclId'], 100, 6, 'deny', '0.0.0.0/8', false, 'PortRange.From' => 22, 'PortRange.To' => 22).body
    end

    tests("#delete_network_acl_entry").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_network_acl_entry(@network_acl['networkAclId'], 100, false).body
    end

    default_acl = Fog::Compute[:aws].describe_network_acls('vpc-id' => @vpc.id, 'default' => true).body['networkAclSet'].first
    @assoc_id   = default_acl['associationSet'].first['networkAclAssociationId']

    tests("#replace_network_acl_association").formats(@network_acl_replace_association) do
      data = Fog::Compute[:aws].replace_network_acl_association(@assoc_id, @network_acl['networkAclId']).body
      @assoc_id = data['newAssociationId']
      data
    end

    tests("#replace_network_acl_association").formats(@network_acl_replace_association) do
      Fog::Compute[:aws].replace_network_acl_association(@assoc_id, default_acl['networkAclId']).body
    end

    # Create another network acl to test tag filters
    test_tags = {'foo' => 'bar'}
    @another_acl = Fog::Compute[:aws].network_acls.create :vpc_id => @vpc.id, :tags => test_tags
    tests("#describe_network_acls('tag-key' => 'foo')").formats(@network_acls_format) do
      body = Fog::Compute[:aws].describe_network_acls('tag-key' => 'foo').body
      tests("returns 1 acl").returns(1) { body['networkAclSet'].size }
      body
    end

    tests("#describe_network_acls('tag-value' => 'bar')").formats(@network_acls_format) do
      body = Fog::Compute[:aws].describe_network_acls('tag-value' => 'bar').body
      tests("returns 1 acl").returns(1) { body['networkAclSet'].size }
      body
    end

    tests("#describe_network_acls('tag:foo' => 'bar')").formats(@network_acls_format) do
      body = Fog::Compute[:aws].describe_network_acls('tag:foo' => 'bar').body
      tests("returns 1 acl").returns(1) { body['networkAclSet'].size }
      body
    end

    tests('#delete_network_acl').formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_network_acl(@network_acl['networkAclId']).body
    end

    # Clean up
    Fog::Compute[:aws].delete_tags(@another_acl.identity, test_tags)
    @another_acl.destroy
    @subnet.destroy
    @vpc.destroy
    Fog::AWS::Compute::Mock.reset if Fog.mocking?
  end
end
