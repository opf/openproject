Shindo.tests('AWS::Elasticache | parameter group requests', ['aws', 'elasticache']) do

  tests('success') do
    pending if Fog.mocking?

    name = 'fog-test'
    description = 'Fog Test Parameter Group'

    tests(
    '#describe_engine_default_parameters'
    ).formats(AWS::Elasticache::Formats::ENGINE_DEFAULTS) do
      response = Fog::AWS[:elasticache].describe_engine_default_parameters
      engine_defaults = response.body['EngineDefaults']
      returns('memcached1.4') { engine_defaults['CacheParameterGroupFamily'] }
      engine_defaults
    end

    tests(
    '#create_cache_parameter_group'
    ).formats(AWS::Elasticache::Formats::SINGLE_PARAMETER_GROUP) do
      body = Fog::AWS[:elasticache].create_cache_parameter_group(name, description).body
      group = body['CacheParameterGroup']
      returns(name)           { group['CacheParameterGroupName'] }
      returns(description)    { group['Description'] }
      returns('memcached1.4') { group['CacheParameterGroupFamily'] }
      body
    end

    tests(
    '#describe_cache_parameters'
    ).formats(AWS::Elasticache::Formats::PARAMETER_SET) do
      response = Fog::AWS[:elasticache].describe_cache_parameters(name)
      parameter_set = response.body['DescribeCacheParametersResult']
      parameter_set
    end

    tests(
    '#describe_cache_parameter_groups without options'
    ).formats(AWS::Elasticache::Formats::DESCRIBE_PARAMETER_GROUPS) do
      body = Fog::AWS[:elasticache].describe_cache_parameter_groups.body
      returns(true, "has #{name}") do
        body['CacheParameterGroups'].any? do |group|
          group['CacheParameterGroupName'] == name
        end
      end
      body
    end

    tests(
    '#reset_cache_parameter_group completely'
    ).formats('CacheParameterGroupName' => String) do
      result = Fog::AWS[:elasticache].reset_cache_parameter_group(
        name
      ).body['ResetCacheParameterGroupResult']
      returns(name) {result['CacheParameterGroupName']}
      result
    end

    tests(
    '#modify_cache_parameter_group'
    ).formats('CacheParameterGroupName' => String) do
      result = Fog::AWS[:elasticache].modify_cache_parameter_group(
        name, {"chunk_size" => 32}
      ).body['ModifyCacheParameterGroupResult']
      returns(name) {result['CacheParameterGroupName']}
      result
    end

    # BUG: returns "MalformedInput - Unexpected complex element termination"
    tests(
    '#reset_cache_parameter_group with one parameter'
    ).formats('CacheParameterGroupName' => String) do
      pending
      result = Fog::AWS[:elasticache].reset_cache_parameter_group(
        name, ["chunk_size"]
      ).body['ResetCacheParameterGroupResult']
      returns(name) {result['CacheParameterGroupName']}
      result
    end

    tests(
    '#describe_cache_parameter_groups with name'
    ).formats(AWS::Elasticache::Formats::DESCRIBE_PARAMETER_GROUPS) do
      body = Fog::AWS[:elasticache].describe_cache_parameter_groups(name).body
      returns(1, "size of 1") { body['CacheParameterGroups'].size }
      returns(name, "has #{name}") do
        body['CacheParameterGroups'].first['CacheParameterGroupName']
      end
      body
    end

    tests(
    '#delete_cache_parameter_group'
    ).formats(AWS::Elasticache::Formats::BASIC) do
      body = Fog::AWS[:elasticache].delete_cache_parameter_group(name).body
    end
  end

  tests('failure') do
    # TODO:
    # Create a duplicate parameter group
    # List a missing parameter group
    # Delete a missing parameter group
  end
end
