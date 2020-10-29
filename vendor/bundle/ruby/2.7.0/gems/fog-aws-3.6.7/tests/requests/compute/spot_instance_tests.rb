Shindo.tests('Fog::Compute[:aws] | spot instance requests', ['aws']) do

  @spot_instance_requests_format = {
    'spotInstanceRequestSet' => [{
      'createTime'                => Time,
      'instanceId'                => Fog::Nullable::String,
      'launchedAvailabilityZone'  => Fog::Nullable::String,
      'launchSpecification'       => {
        'blockDeviceMapping'  => [],
        'groupSet'            => [String],
        'keyName'             => Fog::Nullable::String,
        'imageId'             => String,
        'instanceType'        => String,
        'monitoring'          => Fog::Boolean,
        'ebsOptimized'        => Fog::Boolean,
        'subnetId'            => Fog::Nullable::String,
        'iamInstanceProfile'  => Fog::Nullable::Hash,
      },
      'productDescription'        => String,
      'spotInstanceRequestId'     => String,
      'spotPrice'                 => Float,
      'state'                     => String,
      'type'                      => String,
      'fault'                     => Fog::Nullable::Hash,
    }],
    'requestId' => String
  }

  @cancel_spot_instance_request_format = {
    'spotInstanceRequestSet' => [{
      'spotInstanceRequestId' => String,
      'state'                 => String
    }],
    'requestId' => String
  }

  tests('success') do

    tests("#request_spot_instances('ami-3202f25b', 't1.micro', '0.001')").formats(@spot_instance_requests_format) do
      data = Fog::Compute[:aws].request_spot_instances('ami-3202f25b', 't1.micro', '0.001',{'LaunchSpecification.EbsOptimized' => false}).body
      @spot_instance_request_id = data['spotInstanceRequestSet'].first['spotInstanceRequestId']
      data
    end

    tests("#describe_spot_instance_requests").formats(@spot_instance_requests_format) do
      data = Fog::Compute[:aws].describe_spot_instance_requests('spot-instance-request-id' => [@spot_instance_request_id]).body
    end

    tests("#cancel_spot_instance_requests('#{@spot_instance_request_id}')").formats(@cancel_spot_instance_request_format) do
      Fog::Compute[:aws].cancel_spot_instance_requests(@spot_instance_request_id).body
    end

  end

end
