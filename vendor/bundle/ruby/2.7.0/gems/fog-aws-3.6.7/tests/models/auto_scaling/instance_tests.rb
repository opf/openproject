require 'fog/aws/models/auto_scaling/instance'

Shindo.tests("Fog::AWS::AutoScaling::Instance", 'aws') do
  @instance = Fog::AWS::AutoScaling::Instance.new

  test('#healthy? = true') do
    @instance.health_status = 'Healthy'
    @instance.healthy? == true
  end

  test('#heatlhy? = false') do
    @instance.health_status = 'Unhealthy'
    @instance.healthy? == false
  end
end
