Shindo.tests('AWS::RDS | parameter group requests', ['aws', 'rds']) do
  tests('success') do

    tests("#create_db_parameter_groups").formats(AWS::RDS::Formats::CREATE_DB_PARAMETER_GROUP) do
      body = Fog::AWS[:rds].create_db_parameter_group('fog-group', 'MySQL5.1', 'Some description').body

      returns( 'mysql5.1') { body['CreateDBParameterGroupResult']['DBParameterGroup']['DBParameterGroupFamily']}
      returns( 'fog-group') { body['CreateDBParameterGroupResult']['DBParameterGroup']['DBParameterGroupName']}
      returns( 'Some description') { body['CreateDBParameterGroupResult']['DBParameterGroup']['Description']}

      body
    end

    Fog::AWS[:rds].create_db_parameter_group('other-fog-group', 'MySQL5.1', 'Some description')

    tests("#describe_db_parameter_groups").formats(AWS::RDS::Formats::DESCRIBE_DB_PARAMETER_GROUP) do

      body = Fog::AWS[:rds].describe_db_parameter_groups().body

      returns(4) {body['DescribeDBParameterGroupsResult']['DBParameterGroups'].length}
      body
    end

    tests("#describe_db_parameter_groups('fog-group')").formats(AWS::RDS::Formats::DESCRIBE_DB_PARAMETER_GROUP) do

      body = Fog::AWS[:rds].describe_db_parameter_groups('fog-group').body

      returns(1) {body['DescribeDBParameterGroupsResult']['DBParameterGroups'].length}

      group = body['DescribeDBParameterGroupsResult']['DBParameterGroups'].first
      returns( 'mysql5.1') { group['DBParameterGroupFamily']}
      returns( 'fog-group') { group['DBParameterGroupName']}
      returns( 'Some description') { group['Description']}

      body
    end

    tests("delete_db_parameter_group").formats(AWS::RDS::Formats::BASIC) do
      body = Fog::AWS[:rds].delete_db_parameter_group('fog-group').body

      raises(Fog::AWS::RDS::NotFound) {Fog::AWS[:rds].describe_db_parameter_groups('fog-group')}

      body
    end

    Fog::AWS[:rds].delete_db_parameter_group('other-fog-group')
  end

  tests("failures") do
    raises(Fog::AWS::RDS::NotFound) {Fog::AWS[:rds].describe_db_parameter_groups('doesntexist')}
    raises(Fog::AWS::RDS::NotFound) {Fog::AWS[:rds].delete_db_parameter_group('doesntexist')}

    tests "creating second group with same id" do
      Fog::AWS[:rds].create_db_parameter_group('fog-group', 'MySQL5.1', 'Some description')
      raises(Fog::AWS::RDS::IdentifierTaken) {Fog::AWS[:rds].create_db_parameter_group('fog-group', 'MySQL5.1', 'Some description')}
    end

    Fog::AWS[:rds].delete_db_parameter_group('fog-group')

  end

end
