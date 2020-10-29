Shindo.tests("AWS::CloudWatch | metrics", ['aws', 'cloudwatch']) do

  tests('success') do
    pending # FIXME: the hardcoded instance id won't be available
    tests("#all").succeeds do
      Fog::AWS[:cloud_watch].metrics.all
    end
    instanceId = 'i-fd713391'
    metricName = 'CPUUtilization'
    namespace = 'AWS/EC2'
    tests("#get").returns({:dimensions=>[{"Name"=>"InstanceId", "Value"=>instanceId}], :name=>metricName, :namespace=>namespace}) do
      Fog::AWS[:cloud_watch].metrics.get(namespace, metricName, {'InstanceId' => instanceId}).attributes
    end

  end

  tests('#each') do
    Fog.mock!
    tests("handle NextToken").returns(1001) do
      count = 0
      Fog::AWS[:cloud_watch].metrics.each {|e| count += 1 }
      count
    end

    tests("yields Metrics instances").succeeds do
      all = []
      Fog::AWS[:cloud_watch].metrics.each {|e| all << e }
      all.all? {|e| e.is_a?(Fog::AWS::CloudWatch::Metric) }
    end
  end

end
