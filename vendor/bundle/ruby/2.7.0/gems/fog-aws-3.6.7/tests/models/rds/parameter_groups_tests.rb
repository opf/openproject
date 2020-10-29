Shindo.tests("AWS::RDS | parameter_groups", ['aws', 'rds']) do

  group_name = 'fog-test'
  params = {:id => group_name, :family => 'mysql5.1', :description => group_name}

  pending if Fog.mocking?
  collection_tests(Fog::AWS[:rds].parameter_groups, params, false)
end
