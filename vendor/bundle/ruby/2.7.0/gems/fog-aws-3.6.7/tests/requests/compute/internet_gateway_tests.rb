Shindo.tests('Fog::Compute[:aws] | internet_gateway requests', ['aws']) do

  @internet_gateways_format = {
    'internetGatewaySet' => [{
      'internetGatewayId'        => String,
      'attachmentSet'            => Hash,
      'tagSet'                   => Fog::Nullable::Hash,
    }],
    'requestId' => String
  }

  tests('success') do
    Fog::AWS::Compute::Mock.reset if Fog.mocking?
    @vpc=Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')
    @vpc_id = @vpc.id
    @subnet=Fog::Compute[:aws].subnets.create('vpc_id' => @vpc_id, 'cidr_block' => '10.0.10.0/24')
    @subnet_id = @subnet.subnet_id
    @igw_id = nil

    tests('#create_internet_gateway').formats(@internet_gateways_format) do
      data = Fog::Compute[:aws].create_internet_gateway().body
      @igw_id = data['internetGatewaySet'].first['internetGatewayId']
      data
    end

    tests('#describe_internet_gateways').formats(@internet_gateways_format) do
      Fog::Compute[:aws].describe_internet_gateways.body
    end

    tests('#describe_internet_gateways with tags').formats(@internet_gateways_format) do
      Fog::Compute[:aws].create_tags @igw_id, {"environment" => "production"}
      Fog::Compute[:aws].describe_internet_gateways.body
    end

    tests("#attach_internet_gateway('#{@igw_id}, #{@vpc_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].attach_internet_gateway(@igw_id, @vpc_id).body
    end

    tests("#detach_internet_gateway('#{@igw_id}, #{@vpc_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].detach_internet_gateway(@igw_id, @vpc_id).body
    end

    tests("#delete_internet_gateway('#{@igw_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_internet_gateway(@igw_id).body
    end
    @subnet.destroy
    @vpc.destroy
  end
end
