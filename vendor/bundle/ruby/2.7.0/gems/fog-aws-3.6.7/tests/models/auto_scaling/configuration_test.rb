Shindo.tests('AWS::AutoScaling | configuration', ['aws', 'auto_scaling_m']) do

  params = {
    :id => uniq_id,
    :image_id => 'ami-8c1fece5',
    :instance_type => 't1.micro'
  }

  model_tests(Fog::AWS[:auto_scaling].configurations, params, false) do
    @instance.wait_for { ready? }
  end

end
