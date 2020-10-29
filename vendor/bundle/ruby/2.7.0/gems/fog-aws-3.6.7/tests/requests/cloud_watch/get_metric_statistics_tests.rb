Shindo.tests('AWS::CloudWatch | metric requests', ['aws', 'cloudwatch']) do
  tests('success') do

    @metrics_statistic_format = {
      'GetMetricStatisticsResult' => {
        'Label' => String,
        'Datapoints' => [{
          "Timestamp" => Time,
          'Unit' => String,
          'Minimum' => Float,
          'Maximum' => Float,
          'Average' => Float,
          'Sum' => Float,
          'SampleCount' => Float
        }],
      },
      'ResponseMetadata' => {
        'RequestId' => String
      }
    }

    tests("#get_metric_statistics").formats(@metrics_statistic_format) do
      pending if Fog.mocking?
      instanceId = 'i-420c352f'
      Fog::AWS[:cloud_watch].get_metric_statistics({'Statistics' => ['Minimum','Maximum','Sum','SampleCount','Average'], 'StartTime' => (Time.now-600).iso8601, 'EndTime' => Time.now.iso8601, 'Period' => 60, 'MetricName' => 'DiskReadBytes', 'Namespace' => 'AWS/EC2', 'Dimensions' => [{'Name' => 'InstanceId', 'Value' => instanceId}]}).body
    end
  end
end
