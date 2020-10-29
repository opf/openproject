Shindo.tests('AWS::CloudWatch | metric requests', ['aws', 'cloudwatch']) do
  tests('success') do

    namespace = 'Custom/Test'
    @puts_format = {'ResponseMetadata' => {'RequestId' => String}}

    tests('#puts_value').formats(@puts_format) do
      pending if Fog.mocking?
      Fog::AWS[:cloud_watch].put_metric_data(namespace, [{'MetricName' => 'RequestTest', 'Unit' => 'None', 'Value' => 1}]).body
    end

    tests('#puts_statistics_set').succeeds do
      pending if Fog.mocking?
      Fog::AWS[:cloud_watch].put_metric_data(namespace, [{'MetricName' => 'RequestTest', 'Unit' => 'None', 'StatisticValues' => {'Minimum' => 0, 'Maximum' => 9, 'Sum' => 45, 'SampleCount' => 10, 'Average' => 4.5}}]).body
    end

    tests('#puts with dimensions').succeeds do
      pending if Fog.mocking?
      dimensions = [{}]
      Fog::AWS[:cloud_watch].put_metric_data(namespace, [{'MetricName' => 'RequestTest', 'Unit' => 'None', 'Value' => 1, 'Dimensions' => dimensions}]).body
    end

    tests('#puts more than one').succeeds do
      pending if Fog.mocking?
      datapoints = (0...3).map do |i|
        dp = {'MetricName' => "#{i}RequestTest", 'Unit' => 'None', 'Value' => i}
        if i%2==0
          dp['Dimensions'] = [{'Name' => 'Ruler', 'Value' => "measurement_#{i}"}]
        end
        dp
      end
      Fog::AWS[:cloud_watch].put_metric_data(namespace, datapoints).body
    end

  end
end
