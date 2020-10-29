Shindo.tests('Fog::Compute[:aws] | availability zone requests', ['aws']) do

  @availability_zones_format = {
    'availabilityZoneInfo'  => [{
      'messageSet'  => [],
      'regionName'  => String,
      'zoneName'    => String,
      'zoneState'   => String
    }],
    'requestId'             => String
  }

  tests('success') do

    tests('#describe_availability_zones').formats(@availability_zones_format) do
      Fog::Compute[:aws].describe_availability_zones.body
    end

    tests("#describe_availability_zones('zone-name' => 'us-east-1a')").formats(@availability_zones_format) do
      Fog::Compute[:aws].describe_availability_zones('zone-name' => 'us-east-1a').body
    end

  end

end
