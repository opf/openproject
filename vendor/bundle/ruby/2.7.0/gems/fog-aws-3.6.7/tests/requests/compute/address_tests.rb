Shindo.tests('Fog::Compute[:aws] | address requests', ['aws']) do
  compute = Fog::Compute[:aws]

  @addresses_format = {
    'addressesSet' => [{
      'allocationId'  => Fog::Nullable::String,
      'associationId' => Fog::Nullable::String,
      'domain'        => String,
      'instanceId'    => Fog::Nullable::String,
      'publicIp'      => String
    }],
    'requestId' => String
  }
  @server = compute.servers.create
  @server.wait_for { ready? }
  @ip_address = @server.public_ip_address

  tests('success') do

    @public_ip = nil
    @vpc_public_ip = nil
    @vpc_allocation_id = nil

    tests('#allocate_address').formats({'domain' => String, 'publicIp' => String, 'requestId' => String}) do
      data = compute.allocate_address.body
      @public_ip = data['publicIp']
      data
    end

    tests("#allocate_address('vpc')").formats({'domain' => String, 'publicIp' => String, 'allocationId' => String, 'requestId' => String}) do
      data = compute.allocate_address('vpc').body
      @vpc_public_ip = data['publicIp']
      @vpc_allocation_id = data['allocationId']
      data
    end

    # the following 2 tests imply that your account is old enough that the tested region does not have a default VPC.  These methods do not work with an ip created in a vpc.  this probably means that they will probably fail if they aren't mocked
    tests("#move_address_to_vpc('#{@public_ip}')").formats({'status' => String, 'allocationId' => String, 'requestId' => String}) do
      compute.move_address_to_vpc(@public_ip).body
    end

    tests("#restore_address_to_classic('#{@public_ip}')").formats({'status' => String, 'publicIp' => String, 'requestId' => String}) do
      compute.restore_address_to_classic(@public_ip).body
    end

    tests('#describe_addresses').formats(@addresses_format) do
      compute.describe_addresses.body
    end

    tests("#describe_addresses('public-ip' => #{@public_ip}')").formats(@addresses_format) do
      compute.describe_addresses('public-ip' => @public_ip).body
    end

    tests("#associate_address('#{@server.identity}', '#{@public_ip}')").formats(AWS::Compute::Formats::BASIC) do
      compute.associate_address(@server.identity, @public_ip).body
    end

    tests("#associate_address({:instance_id=>'#{@server.identity}', :public_ip=>'#{@public_ip}'})").formats(AWS::Compute::Formats::BASIC) do
      compute.associate_address({:instance_id=>@server.identity,:public_ip=> @public_ip}).body
    end

    tests("#dissassociate_address('#{@public_ip}')").formats(AWS::Compute::Formats::BASIC) do
      compute.disassociate_address(@public_ip).body
    end

    tests("#associate_address('#{@server.id}', nil, nil, '#{@vpc_allocation_id}')").formats(AWS::Compute::Formats::BASIC) do
      compute.associate_address(@server.id, nil, nil, @vpc_allocation_id).body
    end

    $pry = true
    tests("#associate_address({:instance_id=>'#{@server.id}', :allocation_id=>'#{@vpc_allocation_id}'})").formats(AWS::Compute::Formats::BASIC) do
      compute.associate_address({:instance_id=>@server.id, :allocation_id=>@vpc_allocation_id}).body
    end

    tests("#disassociate_address('#{@vpc_public_ip}')").raises(Fog::AWS::Compute::Error) do
      compute.disassociate_address(@vpc_public_ip)
    end

    tests("#release_address('#{@public_ip}')").formats(AWS::Compute::Formats::BASIC) do
      compute.release_address(@public_ip).body
    end

    tests("#disassociate_address('#{@vpc_public_ip}', '#{@vpc_allocation_id}')").formats(AWS::Compute::Formats::BASIC) do
      address = compute.describe_addresses('public-ip' => @vpc_public_ip).body['addressesSet'].first
      compute.disassociate_address(@vpc_public_ip, address['associationId']).body
    end

    tests("#release_address('#{@vpc_allocation_id}')").formats(AWS::Compute::Formats::BASIC) do
      compute.release_address(@vpc_allocation_id).body
    end
  end

  tests('failure') do

    @address     = compute.addresses.create
    @vpc_address = compute.addresses.create(:domain => 'vpc')

    tests("#associate_addresses({:instance_id =>'i-00000000', :public_ip => '#{@address.identity}')}").raises(Fog::AWS::Compute::NotFound) do
      compute.associate_address({:instance_id => 'i-00000000', :public_ip => @address.identity})
    end

    tests("#associate_addresses({:instance_id =>'#{@server.identity}', :public_ip => '127.0.0.1'})").raises(Fog::AWS::Compute::Error) do
      compute.associate_address({:instance_id => @server.identity, :public_ip => '127.0.0.1'})
    end

    tests("#associate_addresses({:instance_id =>'i-00000000', :public_ip => '127.0.0.1'})").raises(Fog::AWS::Compute::NotFound) do
      compute.associate_address({:instance_id =>'i-00000000', :public_ip =>'127.0.0.1'})
    end

    tests("#restore_address_to_classic('#{@vpc_address.identity}')").raises(Fog::AWS::Compute::Error) do
      compute.restore_address_to_classic(@vpc_address.identity)
    end

    tests("#disassociate_addresses('127.0.0.1') raises BadRequest error").raises(Fog::AWS::Compute::Error) do
      compute.disassociate_address('127.0.0.1')
    end

    tests("#release_address('127.0.0.1')").raises(Fog::AWS::Compute::Error) do
      compute.release_address('127.0.0.1')
    end

    tests("#release_address('#{@vpc_address.identity}')").raises(Fog::AWS::Compute::Error) do
      compute.release_address(@vpc_address.identity)
    end

    if Fog.mocking?
      old_limit = compute.data[:limits][:addresses]

      tests("#allocate_address", "limit exceeded").raises(Fog::AWS::Compute::Error) do
        compute.data[:limits][:addresses] = 0
        compute.allocate_address
      end

      compute.data[:limits][:addresses] = old_limit
    end

    @address.destroy
    @vpc_address.destroy

  end

  @server.destroy

end
