Shindo.tests('AWS::CloudWatch | metric requests', ['aws', 'cloudwatch']) do

  tests('success') do
    @metrics_list_format = {
      'ListMetricsResult' => {
        'Metrics' =>
          [{
            'Dimensions' =>
            [{
              'Name' => String,
              'Value' => String
            }],
            "MetricName" => String,
            "Namespace" => String
          }],
        'NextToken' => Fog::Nullable::String,
      },
      'ResponseMetadata' => {"RequestId"=> String},
    }
    @instanceId = 'i-2f3eab59'
    @dimension_filtered_metrics_list_format = {
      'ListMetricsResult' => {
        'Metrics' =>
          [{
            'Dimensions' =>
            [{
              'Name' => 'InstanceId',
              'Value' => @instanceId
            }],
            "MetricName" => String,
            "Namespace" => String
          }],
        'NextToken' => Fog::Nullable::String,
      },
      'ResponseMetadata' => {"RequestId"=> String},
    }

    tests("#list_metrics").formats(@metrics_list_format) do
      pending if Fog.mocking?
      Fog::AWS[:cloud_watch].list_metrics.body
    end

    tests("#dimension_filtered_list_metrics").formats(@dimension_filtered_metrics_list_format) do
      pending if Fog.mocking?
      Fog::AWS[:cloud_watch].list_metrics('Dimensions' => [{'Name' => 'InstanceId', 'Value' => @instanceId}]).body
    end

    tests("#metric_name_filtered_list_metrics").returns(true) do
      pending if Fog.mocking?
      metricName = "CPUUtilization"
      Fog::AWS[:cloud_watch].list_metrics('MetricName' => metricName).body['ListMetricsResult']['Metrics'].all? do |metric|
        metric['MetricName'] == metricName
      end
    end

    tests("#namespace_filtered_list_metrics").returns(true) do
      pending if Fog.mocking?
      namespace = "AWS/EC2"
      Fog::AWS[:cloud_watch].list_metrics('Namespace' => namespace).body['ListMetricsResult']['Metrics'].all? do |metric|
        metric['Namespace'] == namespace
      end
    end
  end
end
