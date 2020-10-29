Shindo.tests("AWS::CloudWatch | metric_statistics", ['aws', 'cloudwatch']) do

  tests('success') do
    pending if Fog.mocking?

    instanceId = 'i-420c352f'
    metricName = 'DiskReadBytes'
    namespace = 'AWS/EC2'
    startTime = (Time.now-600).iso8601
    endTime = Time.now.iso8601
    period = 60
    statisticTypes = ['Minimum','Maximum','Sum','SampleCount','Average']

    tests("#all").succeeds do
      @statistics = Fog::AWS[:cloud_watch].metric_statistics.all({'Statistics' => statisticTypes, 'StartTime' => startTime, 'EndTime' => endTime, 'Period' => period, 'MetricName' => metricName, 'Namespace' => namespace, 'Dimensions' => [{'Name' => 'InstanceId', 'Value' => instanceId}]})
    end

    tests("#all_not_empty").returns(true) do
      @statistics.length > 0
    end

    new_attributes = {
      :namespace => 'Custom/Test',
      :metric_name => 'ModelTest',
      :value => 9,
      :unit => 'None'
    }
    tests('#new').returns(new_attributes) do
      Fog::AWS[:cloud_watch].metric_statistics.new(new_attributes).attributes
    end

    tests('#create').returns(new_attributes) do
      Fog::AWS[:cloud_watch].metric_statistics.create(new_attributes).attributes
    end

    stats_set_attributes = {
      :namespace => 'Custom/Test',
      :metric_name => 'ModelTest',
      :minimum => 0,
      :maximum => 4,
      :sum => 10,
      :sample_count => 5,
      :average => 2,
      :unit => 'None'
    }
    tests('#create_stats_set').returns(stats_set_attributes) do
      Fog::AWS[:cloud_watch].metric_statistics.create(stats_set_attributes).attributes
    end
  end

end
