Shindo.tests("AWS::RDS | parameter_group", ['aws', 'rds']) do

  group_name = 'fog-test'
  params = {:id => group_name, :family => 'mysql5.1', :description => group_name}

  pending if Fog.mocking?
  model_tests(Fog::AWS[:rds].parameter_groups, params, false) do
    tests('#parameters') do
      #search for a sample parameter
      tests 'contains parameters' do
        returns(true){ @instance.parameters.any? {|p| p.name == 'query_cache_size'}}
      end
    end

    tests('#modify') do
      @instance.modify([{:name => 'query_cache_size', :value => '6553600', :apply_method => 'immediate'}])

      tests 'parameter has changed' do
        returns('6553600'){@instance.parameters.find {|p| p.name == 'query_cache_size'}.value}
      end
    end

  end
end
