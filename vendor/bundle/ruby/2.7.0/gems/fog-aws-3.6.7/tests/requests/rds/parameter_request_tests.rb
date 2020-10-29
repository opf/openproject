Shindo.tests('AWS::RDS | parameter requests', ['aws', 'rds']) do
  tests('success') do
    Fog::AWS[:rds].create_db_parameter_group('fog-group', 'MySQL5.1', 'Some description')

    tests('#modify_db_parameter_group').formats(AWS::RDS::Formats::MODIFY_PARAMETER_GROUP) do
      body = Fog::AWS[:rds].modify_db_parameter_group('fog-group',[
        {'ParameterName' => 'query_cache_size',
        'ParameterValue' => '12345',
        'ApplyMethod' => 'immediate'}
      ]).body

      body
    end

    tests('#describe_db_parameters').formats(AWS::RDS::Formats::DESCRIBE_DB_PARAMETERS) do
      Fog::AWS[:rds].describe_db_parameters('fog-group', :max_records => 20).body
    end

    tests("#describe_db_parameters :source => 'user'")do
      body = Fog::AWS[:rds].describe_db_parameters('fog-group', :source => 'user').body
      returns(1){ body['DescribeDBParametersResult']['Parameters'].length}

      param = body['DescribeDBParametersResult']['Parameters'].first
      returns('query_cache_size'){param['ParameterName']}
      returns('12345'){param['ParameterValue']}
      returns(true){param['IsModifiable']}
      returns('query_cache_size'){param['ParameterName']}
    end
    Fog::AWS[:rds].delete_db_parameter_group('fog-group')

  end
end
