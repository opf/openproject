Shindo.tests('AWS::Elasticache | security group requests', ['aws', 'elasticache']) do

  tests('success') do

    name = 'fog-test'
    description = 'Fog Test Security Group'

    tests(
    '#create_cache_security_group'
    ).formats(AWS::Elasticache::Formats::SINGLE_SECURITY_GROUP) do
      body = Fog::AWS[:elasticache].create_cache_security_group(name, description).body
      group = body['CacheSecurityGroup']
      returns(name)        { group['CacheSecurityGroupName'] }
      returns(description) { group['Description'] }
      returns([], "no authorized security group") { group['EC2SecurityGroups'] }
      body
    end

    tests(
    '#describe_cache_security_groups without options'
    ).formats(AWS::Elasticache::Formats::DESCRIBE_SECURITY_GROUPS) do
      body = Fog::AWS[:elasticache].describe_cache_security_groups.body
      returns(true, "has #{name}") do
        body['CacheSecurityGroups'].any? do |group|
          group['CacheSecurityGroupName'] == name
        end
      end
      body
    end

    tests(
    '#describe_cache_security_groups with name'
    ).formats(AWS::Elasticache::Formats::DESCRIBE_SECURITY_GROUPS) do
      body = Fog::AWS[:elasticache].describe_cache_security_groups(name).body
      returns(1, "size of 1") { body['CacheSecurityGroups'].size }
      returns(name, "has #{name}") do
        body['CacheSecurityGroups'].first['CacheSecurityGroupName']
      end
      body
    end

    tests('authorization') do
      ec2_group = Fog::Compute.new(:provider => 'AWS').security_groups.create(
        :name => 'fog-test-elasticache', :description => 'Fog Test Elasticache'
      )
      # Reload to get the owner_id
      ec2_group.reload

      tests(
      '#authorize_cache_security_group_ingress'
      ).formats(AWS::Elasticache::Formats::SINGLE_SECURITY_GROUP) do
        body = Fog::AWS[:elasticache].authorize_cache_security_group_ingress(
          name, ec2_group.name, ec2_group.owner_id
        ).body
        group = body['CacheSecurityGroup']
        expected_ec2_groups = [{
          'Status' => 'authorizing', 'EC2SecurityGroupName' => ec2_group.name,
          'EC2SecurityGroupOwnerId' => ec2_group.owner_id
        }]
        returns(expected_ec2_groups, 'has correct EC2 groups') do
          group['EC2SecurityGroups']
        end
        body
      end

      # Wait for the state to be active
      Fog.wait_for do
        response = Fog::AWS[:elasticache].describe_cache_security_groups(name)
        group = response.body['CacheSecurityGroups'].first
        group['EC2SecurityGroups'].all? {|ec2| ec2['Status'] == 'authorized'}
      end

      tests(
      '#revoke_cache_security_group_ingress'
      ).formats(AWS::Elasticache::Formats::SINGLE_SECURITY_GROUP) do
        pending if Fog.mocking?

        body = Fog::AWS[:elasticache].revoke_cache_security_group_ingress(
          name, ec2_group.name, ec2_group.owner_id
        ).body
        group = body['CacheSecurityGroup']
        expected_ec2_groups = [{
          'Status' => 'revoking', 'EC2SecurityGroupName' => ec2_group.name,
          'EC2SecurityGroupOwnerId' => ec2_group.owner_id
        }]
        returns(expected_ec2_groups, 'has correct EC2 groups') do
          group['EC2SecurityGroups']
        end
        body
      end

      ec2_group.destroy
    end

    tests(
    '#delete_cache_security_group'
    ).formats(AWS::Elasticache::Formats::BASIC) do
      body = Fog::AWS[:elasticache].delete_cache_security_group(name).body
    end
  end

  tests('failure') do
    # TODO:
    # Create a duplicate security group
    # List a missing security group
    # Delete a missing security group
  end
end
