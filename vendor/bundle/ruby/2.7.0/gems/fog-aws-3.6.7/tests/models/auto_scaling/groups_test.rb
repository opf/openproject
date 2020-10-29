Shindo.tests('AWS::AutoScaling | group', ['aws', 'auto_scaling_m']) do

  params = {
    :id => uniq_id,
    :auto_scaling_group_name => "name",
    :availability_zones => [],
    :launch_configuration_name => "lc"
  }

  lc_params = {
    :id => params[:launch_configuration_name],
    :image_id => "image-id",
    :instance_type => "instance-type",
  }

  Fog::AWS[:auto_scaling].configurations.new(lc_params).save

  model_tests(Fog::AWS[:auto_scaling].groups, params, true) do
    @instance.update
  end

  test("setting attributes in the constructor") do
    group = Fog::AWS[:auto_scaling].groups.new(:min_size => 1, :max_size => 2)
    group.min_size == 1 && group.max_size == 2
  end

end
