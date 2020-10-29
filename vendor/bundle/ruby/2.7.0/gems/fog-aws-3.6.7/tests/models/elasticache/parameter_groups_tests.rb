Shindo.tests('AWS::Elasticache | parameter groups', ['aws', 'elasticache']) do
  group_name = 'fog-test'
  description = 'Fog Test'

  model_tests(
    Fog::AWS[:elasticache].parameter_groups,
    {:id => group_name, :description => description}, true
  )

  collection_tests(
    Fog::AWS[:elasticache].parameter_groups,
    {:id => group_name, :description => description}, true
  )

end
