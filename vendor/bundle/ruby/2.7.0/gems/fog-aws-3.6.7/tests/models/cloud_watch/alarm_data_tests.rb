Shindo.tests("AWS::CloudWatch | alarm_data", ['aws', 'cloudwatch']) do

  pending if Fog.mocking?

  tests('success') do
    tests("#all").succeeds do
      Fog::AWS[:cloud_watch].alarm_data.all
    end

    alarm_name_prefix = {'AlarmNamePrefix'=>'tmp'}
    tests("#all_by_prefix").succeeds do
      Fog::AWS[:cloud_watch].alarm_data.all(alarm_name_prefix)
    end

    namespace = 'AWS/EC2'
    metric_name = 'CPUUtilization'

    tests("#get").succeeds do
      Fog::AWS[:cloud_watch].alarm_data.get(namespace, metric_name).to_json
    end

    new_attributes = {
      :alarm_name => 'tmp-alarm',
      :comparison_operator => 'GreaterThanOrEqualToThreshold',
      :evaluation_periods => 1,
      :metric_name => 'tmp-metric-alarm',
      :namespace => 'fog-0.11.0',
      :period => 60,
      :statistic => 'Sum',
      :threshold => 5
      }
    tests('#new').returns(new_attributes) do
      Fog::AWS[:cloud_watch].alarm_data.new(new_attributes).attributes
    end

    tests('#create').returns(new_attributes) do
      Fog::AWS[:cloud_watch].alarm_data.create(new_attributes).attributes
    end

  end

end
