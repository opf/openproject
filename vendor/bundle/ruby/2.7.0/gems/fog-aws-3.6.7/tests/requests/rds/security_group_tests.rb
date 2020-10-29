Shindo.tests('AWS::RDS | security group requests', ['aws', 'rds']) do
  suffix = rand(65536).to_s(16)

  @sec_group_name  = "fog-sec-group-#{suffix}"
  if Fog.mocking?
    @owner_id = '123456780'
  else
    @owner_id = Fog::AWS[:rds].security_groups.get('default').owner_id
  end

  tests('success') do

    tests("#create_db_security_group").formats(AWS::RDS::Formats::CREATE_DB_SECURITY_GROUP) do
      body = Fog::AWS[:rds].create_db_security_group(@sec_group_name, 'Some description').body

      returns( @sec_group_name) { body['CreateDBSecurityGroupResult']['DBSecurityGroup']['DBSecurityGroupName']}
      returns( 'Some description') { body['CreateDBSecurityGroupResult']['DBSecurityGroup']['DBSecurityGroupDescription']}
      returns( []) { body['CreateDBSecurityGroupResult']['DBSecurityGroup']['EC2SecurityGroups']}
      returns( []) { body['CreateDBSecurityGroupResult']['DBSecurityGroup']['IPRanges']}

      body
    end

    tests("#describe_db_security_groups").formats(AWS::RDS::Formats::DESCRIBE_DB_SECURITY_GROUP) do
      Fog::AWS[:rds].describe_db_security_groups.body
    end

    tests("#authorize_db_security_group_ingress CIDR").formats(AWS::RDS::Formats::AUTHORIZE_DB_SECURITY_GROUP) do
      @cidr = '0.0.0.0/0'
      body = Fog::AWS[:rds].authorize_db_security_group_ingress(@sec_group_name,{'CIDRIP'=>@cidr}).body

      returns("authorizing") { body['AuthorizeDBSecurityGroupIngressResult']['DBSecurityGroup']['IPRanges'].find{|h| h['CIDRIP'] == @cidr}['Status']}
      body
    end

    sec_group = Fog::AWS[:rds].security_groups.get(@sec_group_name)
    sec_group.wait_for {ready?}

    tests("#authorize_db_security_group_ingress another CIDR").formats(AWS::RDS::Formats::AUTHORIZE_DB_SECURITY_GROUP) do
      @cidr = "10.0.0.0/24"
      body = Fog::AWS[:rds].authorize_db_security_group_ingress(@sec_group_name,{'CIDRIP'=>@cidr}).body

      returns("authorizing") { body['AuthorizeDBSecurityGroupIngressResult']['DBSecurityGroup']['IPRanges'].find{|h| h['CIDRIP'] == @cidr}['Status']}
      body
    end

    sec_group = Fog::AWS[:rds].security_groups.get(@sec_group_name)
    sec_group.wait_for {ready?}

    tests("#count CIDRIP").formats(AWS::RDS::Formats::DESCRIBE_DB_SECURITY_GROUP) do
      body = Fog::AWS[:rds].describe_db_security_groups(@sec_group_name).body
      returns(2) { body['DescribeDBSecurityGroupsResult']['DBSecurityGroups'][0]['IPRanges'].size }
      body
    end

    tests("#revoke_db_security_group_ingress CIDR").formats(AWS::RDS::Formats::REVOKE_DB_SECURITY_GROUP) do
      @cidr = '0.0.0.0/0'
      body = Fog::AWS[:rds].revoke_db_security_group_ingress(@sec_group_name,{'CIDRIP'=> @cidr}).body
      returns("revoking") { body['RevokeDBSecurityGroupIngressResult']['DBSecurityGroup']['IPRanges'].find{|h| h['CIDRIP'] == @cidr}['Status']}
      body
    end

    tests("#authorize_db_security_group_ingress EC2").formats(AWS::RDS::Formats::AUTHORIZE_DB_SECURITY_GROUP) do
      @ec2_sec_group = 'default'
      body = Fog::AWS[:rds].authorize_db_security_group_ingress(@sec_group_name,{'EC2SecurityGroupName' => @ec2_sec_group, 'EC2SecurityGroupOwnerId' => @owner_id}).body

      returns("authorizing") { body['AuthorizeDBSecurityGroupIngressResult']['DBSecurityGroup']['EC2SecurityGroups'].find{|h| h['EC2SecurityGroupName'] == @ec2_sec_group}['Status']}
      returns(@owner_id) { body['AuthorizeDBSecurityGroupIngressResult']['DBSecurityGroup']['EC2SecurityGroups'].find{|h| h['EC2SecurityGroupName'] == @ec2_sec_group}['EC2SecurityGroupOwnerId']}
      body
    end

    tests("duplicate #authorize_db_security_group_ingress EC2").raises(Fog::AWS::RDS::AuthorizationAlreadyExists) do
      @ec2_sec_group = 'default'

      Fog::AWS[:rds].authorize_db_security_group_ingress(@sec_group_name,{'EC2SecurityGroupName' => @ec2_sec_group, 'EC2SecurityGroupOwnerId' => @owner_id})
    end

    sec_group = Fog::AWS[:rds].security_groups.get(@sec_group_name)
    sec_group.wait_for {ready?}

    tests("#revoke_db_security_group_ingress EC2").formats(AWS::RDS::Formats::REVOKE_DB_SECURITY_GROUP) do
      @ec2_sec_group = 'default'

      body = Fog::AWS[:rds].revoke_db_security_group_ingress(@sec_group_name,{'EC2SecurityGroupName' => @ec2_sec_group, 'EC2SecurityGroupOwnerId' => @owner_id}).body

      returns("revoking") { body['RevokeDBSecurityGroupIngressResult']['DBSecurityGroup']['EC2SecurityGroups'].find{|h| h['EC2SecurityGroupName'] == @ec2_sec_group}['Status']}
      body
    end


    #TODO, authorize ec2 security groups

    tests("#delete_db_security_group").formats(AWS::RDS::Formats::BASIC) do
      body = Fog::AWS[:rds].delete_db_security_group(@sec_group_name).body

      raises(Fog::AWS::RDS::NotFound) {Fog::AWS[:rds].describe_db_security_groups(@sec_group_name)}

      body
    end
  end
end
