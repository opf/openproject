Shindo.tests("AWS::CloudWatch | alarm_histories", ['aws', 'cloudwatch']) do

  pending if Fog.mocking?

  tests('success') do
    tests("#all").succeeds do
      Fog::AWS[:cloud_watch].alarm_histories.all
    end

  new_attributes = {
      :alarm_name => 'tmp-alarm',
      :end_date => '',
      :history_item_type => 'StateUpdate',
      :max_records => 1,
      :start_date => ''
    }
    tests('#new').returns(new_attributes) do
      Fog::AWS[:cloud_watch].alarm_histories.new(new_attributes).attributes
    end
  end

end
