Shindo.tests('AWS::AutoScaling | configurations', ['aws', 'auto_scaling_m']) do

  params = {
    :id => uniq_id,
    :image_id => 'ami-8c1fece5',
    :instance_type => 't1.micro'
  }

  collection_tests(Fog::AWS[:auto_scaling].configurations, params, false)

end
