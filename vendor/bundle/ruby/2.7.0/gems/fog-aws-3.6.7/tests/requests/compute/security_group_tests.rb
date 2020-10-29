Shindo.tests('Fog::Compute[:aws] | security group requests', ['aws']) do
  # See https://github.com/fog/fog/issues/2932hj0
  pending

  @create_security_group_format = {
    'requestId' => String,
    'groupId'   => String,
    'return'    => Fog::Boolean
  }

  @security_groups_format = {
    'requestId'           => String,
    'securityGroupInfo' => [{
      'groupDescription'  => String,
      'groupId'           => Fog::Nullable::String,
      'groupName'         => String,
      'ipPermissions'     => [{
        'fromPort'    => Fog::Nullable::Integer,
        'groups'      => [{ 'groupName' => Fog::Nullable::String, 'userId' => String, 'groupId' => String }],
        'ipProtocol'  => String,
        'ipRanges'    => [Fog::Nullable::Hash],
        'toPort'      => Fog::Nullable::Integer,
      }],
      'ipPermissionsEgress' => [],
      'ownerId'           => String,
      'vpcId'             => Fog::Nullable::String
    }]
  }

  @owner_id = Fog::Compute[:aws].describe_security_groups('group-name' => 'default').body['securityGroupInfo'].first['ownerId']
  @group_id_default = Fog::Compute[:aws].describe_security_groups('group-name' => 'default').body['securityGroupInfo'].first['groupId']

  tests('success') do

    tests("#create_security_group('fog_security_group', 'tests group')").formats(@create_security_group_format) do
      Fog::Compute[:aws].create_security_group('fog_security_group', 'tests group').body
    end
    tests("#create_security_group('fog_security_group_two', 'tests group')").formats(@create_security_group_format) do
      Fog::Compute[:aws].create_security_group('fog_security_group_two', 'tests group').body
    end
    @group_id_two = Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group_two').body['securityGroupInfo'].first['groupId']
    group_id = Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['groupId']
    to_be_revoked = []
    expected_permissions = []

    permission = { 'SourceSecurityGroupName' => 'default' }
    tests("#authorize_security_group_ingress('fog_security_group', #{permission.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', permission).body
    end

    to_be_revoked.push([permission, expected_permissions.dup])

    expected_permissions = [
      {"groups"=>[{"groupName"=>"default", "userId"=>@owner_id, "groupId"=>@group_id_default}],
        "fromPort"=>1,
        "ipRanges"=>[],
        "ipProtocol"=>"tcp",
        "toPort"=>65535},
      {"groups"=>[{"groupName"=>"default", "userId"=>@owner_id, "groupId"=>@group_id_default}],
        "fromPort"=>1,
        "ipRanges"=>[],
        "ipProtocol"=>"udp",
        "toPort"=>65535},
      {"groups"=>[{"groupName"=>"default", "userId"=>@owner_id, "groupId"=>@group_id_default}],
        "fromPort"=>-1,
        "ipRanges"=>[],
        "ipProtocol"=>"icmp",
        "toPort"=>-1}
    ]

    tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    tests("#describe_security_groups('group-id' => '#{group_id}')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-id' => group_id).body['securityGroupInfo'].first['ipPermissions'])
    end

    permission = { 'SourceSecurityGroupName' => 'fog_security_group_two', 'SourceSecurityGroupOwnerId' => @owner_id }
    tests("#authorize_security_group_ingress('fog_security_group', #{permission.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', permission).body
    end

    to_be_revoked.push([permission, expected_permissions.dup])

    expected_permissions = [
      {"groups"=>
        [{"userId"=>@owner_id, "groupName"=>"default", "groupId"=>@group_id_default},
          {"userId"=>@owner_id, "groupName"=>"fog_security_group_two", "groupId"=>@group_id_two}],
        "ipRanges"=>[],
        "ipProtocol"=>"tcp",
        "fromPort"=>1,
        "toPort"=>65535},
      {"groups"=>
        [{"userId"=>@owner_id, "groupName"=>"default", "groupId"=>@group_id_default},
          {"userId"=>@owner_id, "groupName"=>"fog_security_group_two", "groupId"=>@group_id_two}],
        "ipRanges"=>[],
        "ipProtocol"=>"udp",
        "fromPort"=>1,
        "toPort"=>65535},
      {"groups"=>
        [{"userId"=>@owner_id, "groupName"=>"default", "groupId"=>@group_id_default},
          {"userId"=>@owner_id, "groupName"=>"fog_security_group_two", "groupId"=>@group_id_two}],
        "ipRanges"=>[],
        "ipProtocol"=>"icmp",
        "fromPort"=>-1,
        "toPort"=>-1}
    ]

    tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    permission = { 'IpProtocol' => 'tcp', 'FromPort' => '22', 'ToPort' => '22' }
    tests("#authorize_security_group_ingress('fog_security_group', #{permission.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', permission).body
    end

    to_be_revoked.push([permission, expected_permissions.dup])

    # previous did nothing
    tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    permission = { 'IpProtocol' => 'tcp', 'FromPort' => '22', 'ToPort' => '22', 'CidrIp' => '10.0.0.0/8' }
    tests("#authorize_security_group_ingress('fog_security_group', #{permission.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', permission).body
    end

    to_be_revoked.push([permission, expected_permissions.dup])

    expected_permissions += [
      {"groups"=>[],
        "ipRanges"=>[{"cidrIp"=>"10.0.0.0/8"}],
        "ipProtocol"=>"tcp",
        "fromPort"=>22,
        "toPort"=>22}
    ]

    tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    # authorize with nested IpProtocol without IpRanges or Groups does nothing
    permissions = {
      'IpPermissions' => [
        { 'IpProtocol' => 'tcp', 'FromPort' => '22', 'ToPort' => '22' }
      ]
    }
    tests("#authorize_security_group_ingress('fog_security_group', #{permissions.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', permissions).body
    end

    to_be_revoked.push([permissions, expected_permissions.dup])

    # previous did nothing
    tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    # authorize with nested IpProtocol with IpRanges
    permissions = {
      'IpPermissions' => [
        {
          'IpProtocol' => 'tcp', 'FromPort' => '80', 'ToPort' => '80',
          'IpRanges' => [{ 'CidrIp' => '192.168.0.0/24' }]
        }
      ]
    }
    tests("#authorize_security_group_ingress('fog_security_group', #{permissions.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', permissions).body
    end

    to_be_revoked.push([permissions, expected_permissions.dup])

    expected_permissions += [
      {"groups"=>[],
        "ipRanges"=>[{"cidrIp"=>"192.168.0.0/24"}],
        "ipProtocol"=>"tcp",
        "fromPort"=>80,
        "toPort"=>80}
    ]

    tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    # authorize with nested IpProtocol with Groups
    permissions = {
      'IpPermissions' => [
        {
          'IpProtocol' => 'tcp', 'FromPort' => '8000', 'ToPort' => '8000',
          'Groups' => [{ 'GroupName' => 'fog_security_group_two' }]
        }
      ]
    }
    tests("#authorize_security_group_ingress('fog_security_group', #{permissions.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', permissions).body
    end

    to_be_revoked.push([permissions, expected_permissions.dup])

    expected_permissions += [
      {"groups"=>[{"userId"=>@owner_id, "groupName"=>"fog_security_group_two", "groupId"=>@group_id_two}],
        "ipRanges"=>[],
        "ipProtocol"=>"tcp",
        "fromPort"=>8000,
        "toPort"=>8000}
    ]
    tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    # authorize with nested IpProtocol with IpRanges and Groups
    # try integers on this one instead of strings
    permissions = {
      'IpPermissions' => [
        {
          'IpProtocol' => 'tcp', 'FromPort' => 9000, 'ToPort' => 9000,
          'IpRanges' => [{ 'CidrIp' => '172.16.0.0/24' }],
          'Groups' => [{ 'GroupName' => 'fog_security_group_two' }]
        }
      ]
    }
    tests("#authorize_security_group_ingress('fog_security_group', #{permissions.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', permissions).body
    end

    to_be_revoked.push([permissions, expected_permissions.dup])

    expected_permissions += [
      {"groups"=>
        [{"userId"=>@owner_id, "groupName"=>"fog_security_group_two", "groupId"=>@group_id_two}],
        "ipRanges"=>[{"cidrIp"=>"172.16.0.0/24"}],
        "ipProtocol"=>"tcp",
        "fromPort"=>9000,
        "toPort"=>9000}
    ]

    tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    tests("#describe_security_groups").formats(@security_groups_format) do
      Fog::Compute[:aws].describe_security_groups.body
    end

    tests("#describe_security_groups('group-name' => 'fog_security_group')").formats(@security_groups_format) do
      Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body
    end

    to_be_revoked.reverse.each do |permission, expected_permissions_after|
      tests("#revoke_security_group_ingress('fog_security_group', #{permission.inspect})").formats(AWS::Compute::Formats::BASIC) do
        Fog::Compute[:aws].revoke_security_group_ingress('fog_security_group', permission).body
      end

      tests("#describe_security_groups('group-name' => 'fog_security_group')").returns([]) do
        array_differences(expected_permissions_after, Fog::Compute[:aws].describe_security_groups('group-name' => 'fog_security_group').body['securityGroupInfo'].first['ipPermissions'])
      end
    end

    tests("#delete_security_group('fog_security_group')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_security_group('fog_security_group').body
    end

    tests("#delete_security_group('fog_security_group_two')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_security_group('fog_security_group_two').body
    end

    vpc_id = Fog::Compute[:aws].create_vpc('10.255.254.64/28').body['vpcSet'].first['vpcId']

    # Create security group in VPC
    tests("#create_security_group('vpc_security_group', 'tests group')").formats(@create_security_group_format) do
      Fog::Compute[:aws].create_security_group('vpc_security_group', 'tests group', vpc_id).body
    end

    group_id = Fog::Compute[:aws].describe_security_groups('group-name' => 'vpc_security_group').body['securityGroupInfo'].first['groupId']

    permissions = {
      'IpPermissions' => [
        {
          'IpProtocol' => '42',
          'IpRanges' => [{ 'CidrIp' => '10.0.0.0/8' }],
        }
      ]
    }

    expected_permissions = [
      {"groups"=>[],
        "ipRanges"=>[{"cidrIp"=>"10.0.0.0/8"}],
        "ipProtocol"=>"42"}
    ]

    options = permissions.clone
    options['GroupId'] = group_id
    tests("#authorize_security_group_ingress(#{options.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress(options).body
    end

    tests("#describe_security_groups('group-name' => 'vpc_security_group')").returns([]) do
      array_differences(expected_permissions, Fog::Compute[:aws].describe_security_groups('group-name' => 'vpc_security_group').body['securityGroupInfo'].first['ipPermissions'])
    end

    tests("#revoke_security_group_ingress(#{options.inspect})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].revoke_security_group_ingress(options).body
    end

    vpc_group=Fog::Compute[:aws].security_groups.get_by_id(group_id)
    vpc_group.destroy

    Fog::Compute[:aws].delete_vpc(vpc_id)

  end
  ## Rate limiting seems to want us to take a break otherwise it will throw errors
  tests('failure') do

    @security_group = Fog::Compute[:aws].security_groups.create(:description => 'tests group', :name => 'fog_security_group')
    @other_security_group = Fog::Compute[:aws].security_groups.create(:description => 'tests group', :name => 'fog_other_security_group')

    tests("duplicate #create_security_group(#{@security_group.name}, #{@security_group.description})").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].create_security_group(@security_group.name, @security_group.description)
    end

    tests("#authorize_security_group_ingress('not_a_group_name', {'FromPort' => 80, 'IpProtocol' => 'tcp', 'toPort' => 80})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].authorize_security_group_ingress(
        'not_a_group_name',
        {
          'FromPort' => 80,
          'IpProtocol' => 'tcp',
          'ToPort' => 80,
        }
      )
    end

    tests("#authorize_security_group_ingress('not_a_group_name', {'SourceSecurityGroupName' => 'not_a_group_name', 'SourceSecurityGroupOwnerId' => '#{@owner_id}'})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].authorize_security_group_ingress(
        'not_a_group_name',
        {
          'SourceSecurityGroupName'     => 'not_a_group_name',
          'SourceSecurityGroupOwnerId'  => @owner_id
        }
      )
    end

    tests("#authorize_security_group_ingress('fog_security_group', {'IpPermissions' => [{'IpProtocol' => 'tcp', 'FromPort' => 80, 'ToPort' => 80, 'IpRanges' => [{'CidrIp' => '10.0.0.0/8'}]}]})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', {'IpPermissions' => [{'IpProtocol' => 'tcp', 'FromPort' => 80, 'ToPort' => 80, 'IpRanges' => [{'CidrIp' => '10.0.0.0/8'}]}]}).body
    end

    tests("#authorize_security_group_ingress('fog_security_group', {'IpPermissions' => [{'IpProtocol' => 'tcp', 'FromPort' => 80, 'ToPort' => 80, 'IpRanges' => [{'CidrIp' => '10.0.0.0/8'}]}]})").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', {'IpPermissions' => [{'IpProtocol' => 'tcp', 'FromPort' => 80, 'ToPort' => 80, 'IpRanges' => [{'CidrIp' => '10.0.0.0/8'}]}]})
    end

    tests("#authorize_security_group_ingress('fog_security_group', {'IpPermissions' => [{'Groups' => [{'GroupName' => '#{@other_security_group.name}'}], 'FromPort' => 80, 'ToPort' => 80, 'IpProtocol' => 'tcp'}]})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', {'IpPermissions' => [{'Groups' => [{'GroupName' => @other_security_group.name}], 'FromPort' => 80, 'ToPort' => 80, 'IpProtocol' => 'tcp'}]}).body
    end

    tests("#delete_security_group('#{@other_security_group.name}')").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].delete_security_group(@other_security_group.name)
    end

    broken_params = [
      {},
      { "IpProtocol" => "what" },
      { "IpProtocol" => "tcp" },
      { "IpProtocol" => "what", "FromPort" => 1, "ToPort" => 1 },
    ]
    broken_params += broken_params.map do |broken_params_item|
      { "IpPermissions" => [broken_params_item] }
    end
    broken_params += [
      { "IpPermissions" => [] },
      { "IpPermissions" => nil }
    ]

    broken_params.each do |broken_params_item|
      tests("#authorize_security_group_ingress('fog_security_group', #{broken_params_item.inspect})").raises(Fog::AWS::Compute::Error) do
        Fog::Compute[:aws].authorize_security_group_ingress('fog_security_group', broken_params_item)
      end

      tests("#revoke_security_group_ingress('fog_security_group', #{broken_params_item.inspect})").raises(Fog::AWS::Compute::Error) do
        Fog::Compute[:aws].revoke_security_group_ingress('fog_security_group', broken_params_item)
      end
    end

    tests("#revoke_security_group_ingress('not_a_group_name', {'FromPort' => 80, 'IpProtocol' => 'tcp', 'toPort' => 80})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].revoke_security_group_ingress(
        'not_a_group_name',
        {
          'FromPort' => 80,
          'IpProtocol' => 'tcp',
          'ToPort' => 80,
        }
      )
    end

    tests("#revoke_security_group_ingress('not_a_group_name', {'SourceSecurityGroupName' => 'not_a_group_name', 'SourceSecurityGroupOwnerId' => '#{@owner_id}'})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].revoke_security_group_ingress(
        'not_a_group_name',
        {
          'SourceSecurityGroupName'     => 'not_a_group_name',
          'SourceSecurityGroupOwnerId'  => @owner_id
        }
      )
    end

    tests("#delete_security_group('not_a_group_name')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].delete_security_group('not_a_group_name')
    end

    @rds_security_group = Fog::AWS[:rds].security_groups.create(:id => "rdsgroup", :description => 'fog rds test')

    tests("#delete_security_group('when authorized to an rds firewall')").raises(Fog::AWS::Compute::Error) do
      @rds_security_group.authorize_ec2_security_group(@security_group.name)
      Fog::Compute[:aws].delete_security_group(@security_group.name)
    end

    @rds_security_group.destroy

    @security_group.destroy
    @other_security_group.destroy

    tests("#delete_security_group('default')").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].delete_security_group('default')
    end

    broken_params = [
                     ['fog_security_group', { 'GroupName' => 'fog_security_group' }],
                     [nil, nil],
                     [nil, { 'GroupId' => nil }],
                     [nil, { 'GroupName' => nil, 'GroupId' => nil }]
                    ]

    broken_params.each do |list_elem|
      tests("#authorize_security_group_ingress(#{list_elem[0].inspect}, #{list_elem[1].inspect})").raises(Fog::AWS::Compute::Error) do
        Fog::Compute[:aws].authorize_security_group_ingress(list_elem[0], list_elem[1])
      end

      tests("#revoke_security_group_ingress(#{list_elem[0].inspect}, #{list_elem[1].inspect})").raises(Fog::AWS::Compute::Error) do
        Fog::Compute[:aws].revoke_security_group_ingress(list_elem[0], list_elem[1])
      end
    end

  end

end
