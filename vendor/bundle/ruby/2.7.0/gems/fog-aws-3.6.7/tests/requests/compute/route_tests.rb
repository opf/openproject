Shindo.tests('Fog::Compute[:aws] | route table requests', ['aws']) do

  @route_table_format = {
    'routeTable' => [{
      'routeSet'        => [{
        'destinationCidrBlock'  => String,
        'gatewayId'             => String,
        'state'                 => String,
      }],
      'tagSet'          => Hash,
      'associationSet'  => Array,
      'routeTableId'    => String,
      'vpcId'           => String,
    }],
    'requestId'   => String
  }

  @route_tables_format = {
    'routeTableSet' => [{
      'associationSet' => [{
        'routeTableAssociationId' => Fog::Nullable::String,
        'routeTableId'            => String,
        'subnetId'                => Fog::Nullable::String,
        'main'                    => Fog::Boolean
      }],
      'tagSet'         => Hash,
      'routeSet'       => [{
        'destinationCidrBlock'   => String,
        'gatewayId'              => Fog::Nullable::String,
        'instanceId'             => Fog::Nullable::String,
        'instanceOwnerId'        => Fog::Nullable::String,
        'networkInterfaceId'     => Fog::Nullable::String,
        'vpcPeeringConnectionId' => Fog::Nullable::String,
        'natGatewayId'           => Fog::Nullable::String,
        'state'                  => String,
        'origin'                 => String
      }],
      'routeTableId'   => String,
      'vpcId'          => String,
    }],
    'requestId'    => String
  }

  Fog::AWS::Compute::Mock.reset if Fog.mocking?
  vpc = Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')
  if !Fog.mocking?
    vpc.wait_for { state.eql? "available" }
  end
  @subnet_id = Fog::Compute[:aws].create_subnet(vpc.id, '10.0.10.0/24').body['subnet']['subnetId']
  @network_interface = Fog::Compute[:aws].create_network_interface(@subnet_id, {"PrivateIpAddress" => "10.0.10.23"}).body
  @internet_gateway_id = Fog::Compute[:aws].create_internet_gateway.body['internetGatewaySet'].first['internetGatewayId']
  @alt_internet_gateway_id = Fog::Compute[:aws].create_internet_gateway.body['internetGatewaySet'].first['internetGatewayId']
  @network_interface_id = @network_interface['networkInterface']['networkInterfaceId']
  key_name = uniq_id('fog-test-key')
  key = Fog::Compute[:aws].key_pairs.create(:name => key_name)
  @cidr_block = '10.0.10.0/24'
  @destination_cidr_block = '10.0.10.0/23'
  @ami = 'ami-79c0ae10' # ubuntu 12.04 daily build 20120728

  tests('success') do

    # Test create_route_table
    #
    tests("#create_route_table('#{vpc.id}')").formats(@route_table_format) do
      data = Fog::Compute[:aws].create_route_table(vpc.id).body
      @route_table_id = data['routeTable'].first['routeTableId']
      data
    end

    # Test associate_route_table
    #
    tests("#associate_route_table('#{@route_table_id}', '#{@subnet_id}')").formats({'requestId'=>String, 'associationId'=>String}) do
      data = Fog::Compute[:aws].associate_route_table(@route_table_id, @subnet_id).body
      @association_id = data['associationId']
      data
    end

    # Tests create_route
    #   - using internet gateway
    #   - using instance id
    #   - using network interface
    #
    Fog::Compute[:aws].attach_internet_gateway(@internet_gateway_id, vpc.id).body
    tests("#create_route('#{@route_table_id}', '#{@destination_cidr_block}', '#{@internet_gateway_id}', 'nil')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].create_route(@route_table_id, @destination_cidr_block, @internet_gateway_id, nil).body
    end

    instance = Fog::Compute[:aws].servers.create(:image_id => @ami, :flavor_id => 't1.micro', :key_name => key_name, :subnet_id => @subnet_id)
    instance.wait_for { state.eql? "running" }
    tests("#create_route('#{@route_table_id}', '10.0.10.0/22', 'nil', '#{instance.id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].create_route(@route_table_id, '10.0.10.0/22', nil, instance.id).body
    end

    tests("#create_route('#{@route_table_id}', '10.0.10.0/21', 'nil', 'nil', '#{@network_interface_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].create_route(@route_table_id, '10.0.10.0/21', nil, nil, @network_interface_id).body
    end

    # Tests replace_route
    #   - using internet gateway
    #   - using instance id
    #   - using network interface
    #
    Fog::Compute[:aws].attach_internet_gateway(@alt_internet_gateway_id, vpc.id).body
    tests("#replace_route('#{@route_table_id}', '#{@destination_cidr_block}', {'gatewayId' => '#{@alt_internet_gateway_id}'})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].replace_route(@route_table_id, @destination_cidr_block, {'gatewayId' => @alt_internet_gateway_id}).body
    end

    instance = Fog::Compute[:aws].servers.create(:image_id => @ami, :flavor_id => 't1.micro', :key_name => key_name, :subnet_id => @subnet_id)
    instance.wait_for { state.eql? "running" }
    tests("#replace_route('#{@route_table_id}', '10.0.10.0/22', {'instanceId' => '#{instance.id}'})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].replace_route(@route_table_id, '10.0.10.0/22', {'instanceId' => instance.id}).body
    end

    tests("#replace_route('#{@route_table_id}', '10.0.10.0/21', {'networkInterfaceId' => '#{@network_interface_id}'})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].replace_route(@route_table_id, '10.0.10.0/21', {'networkInterfaceId' => @network_interface_id}).body
    end

    # Tests describe_route_tables
    #   - no parameters
    #   - filter: vpc-id => vpc_id
    #   - filter: vpc-id => ['all']
    #
    tests('#describe_route_tables').formats(@route_tables_format) do
      Fog::Compute[:aws].describe_route_tables.body
    end
    tests("#describe_route_tables('vpc-id' => #{vpc.id})").formats(@route_tables_format) do
      Fog::Compute[:aws].describe_route_tables('vpc-id' => vpc.id).body
    end
    tests("#describe_route_tables('vpc-id' => ['all'])").formats(@route_tables_format) do
      Fog::Compute[:aws].describe_route_tables('vpc-id' => ['all']).body
    end

    # Test delete_route(route_table_id, cidr_block)
    #
    tests("#delete_route('#{@route_table_id}', '10.0.10.0/21')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_route(@route_table_id, '10.0.10.0/21').body
    end
    tests("#delete_route('#{@route_table_id}', '10.0.10.0/22')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_route(@route_table_id, '10.0.10.0/22').body
    end

    Fog::Compute[:aws].servers.all('instance-id'=>instance.id).first.destroy
    if !Fog.mocking?
      instance.wait_for { state.eql? "terminated" }
    end
    tests("#delete_route('#{@route_table_id}', '#{@destination_cidr_block}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_route(@route_table_id, @destination_cidr_block).body
    end

    # Test disassociate_route_table(association_id)
    #
    tests("#disassociate_route_table('#{@association_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].disassociate_route_table(@association_id).body
    end

    # Test delete_route_table(route_table_id)
    #
    tests("#delete_route_table('#{@route_table_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_route_table(@route_table_id).body
    end
  end
  tests('failure') do

    @route_table_id = Fog::Compute[:aws].create_route_table(vpc.id).body['routeTable'].first['routeTableId']
    @association_id = Fog::Compute[:aws].associate_route_table(@route_table_id, @subnet_id).body['associationId']
    Fog::Compute[:aws].create_route(@route_table_id, @destination_cidr_block, @internet_gateway_id, nil)
    instance = Fog::Compute[:aws].servers.create(:image_id => @ami, :flavor_id => 't1.micro', :key_name => key_name, :subnet_id => @subnet_id)
    instance.wait_for { state.eql? "running" }

    # Tests create_route_table
    #   - no parameters
    #   - passing a nonexisting vpc
    #
    tests('#create_route_table').raises(ArgumentError) do
      Fog::Compute[:aws].create_route_table
    end
    tests("#create_route_table('vpc-00000000')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].create_route_table('vpc-00000000')
    end

    # Tests associate_route_table
    #   - no parameters
    #   - passing a nonexisiting route table
    #   - passing a nonexisiting subnet
    #
    tests('#associate_route_table').raises(ArgumentError) do
      Fog::Compute[:aws].associate_route_table
    end
    tests("#associate_route_table('rtb-00000000', '#{@subnet_id}')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].associate_route_table('rtb-00000000', @subnet_id)
    end
    tests("#associate_route_table('#{@route_table_id}', 'subnet-00000000')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].associate_route_table(@route_table_id, 'subnet-00000000')
    end

    # Tests create_route
    #    - no parameters
    #    - passing a nonexisiting route table and an exisiting internet gateway
    #    - passing a nonexisiting internet gateway
    #    - passing a nonexisting route table and an exisiting instance
    #    - passing a nonexisiting instance
    #    - passing a nonexsiting route table and an exisiting network interface
    #    - passing a nonexisiting network interface
    #    - attempting to add a route at the same destination cidr block as another
    #    - attempting to add a route at a less specific destination cidr block
    #
    tests('#create_route').raises(ArgumentError) do
      Fog::Compute[:aws].create_route
    end
    tests("#create_route('rtb-00000000', '#{@destination_cidr_block}', '#{@internet_gateway_id}')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].create_route('rtb-00000000', @destination_cidr_block, @internet_gateway_id)
    end
    tests("#create_route('#{@route_table_id}', '#{@destination_cidr_block}', 'igw-00000000')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].create_route(@route_table_id, @destination_cidr_block, 'igw-00000000')
    end
    tests("#create_route('rtb-00000000', '#{@destination_cidr_block}', 'nil', '#{instance.id}')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].create_route('rtb-00000000', @destination_cidr_block, instance.id)
    end
    tests("#create_route('#{@route_table_id}', '#{@destination_cidr_block}', 'nil', 'i-00000000')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].create_route(@route_table_id, @destination_cidr_block, nil, 'i-00000000')
    end
    tests("#create_route('#{@route_table_id}', '#{@destinationCidrBlock}', 'nil', 'nil', 'eni-00000000')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].create_route(@route_table_id, @destination_cidr_block, nil, nil, 'eni-00000000')
    end
    tests("#create_route('#rtb-00000000', '#{@destination_cidr_block}', 'nil, 'nil', '#{@network_interface_id}')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].create_route('rtb-00000000', @destination_cidr_block, nil, nil, @network_interface_id)
    end
    tests("#create_route same destination_cidr_block").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].create_route(@route_table_id, @destination_cidr_block, @internet_gateway_id)
      Fog::Compute[:aws].create_route(@route_table_id, @destination_cidr_block, nil, nil, @network_interface_id).body
    end
    if !Fog.mocking?
      tests("#create_route less specific destination_cidr_block").raises(Fog::AWS::Compute::Error) do
        Fog::Compute[:aws].create_route(@route_table_id, '10.0.10.0/25', @internet_gateway_id)
       Fog::Compute[:aws].delete_route(@route_table_id, @destination_cidr_block).body
      end
    end

    # Tests replace_route
    #   - no parameters
    #   - passing a nonexisiting route table and an exisiting internet gateway
    #   - passing a nonexisiting route table
    #   - passing a nonexisting route table and an exisiting instance
    #   - passing a nonexisiting instance
    #   - passing a nonexsiting route table and an exisiting network interface
    #   - passing a nonexisiting network interface
    #   - attempting to add a route at a less specific destination cidr block
    #
    tests('#replace_route').raises(ArgumentError) do
      Fog::Compute[:aws].replace_route
    end
    tests("#replace_route('rtb-00000000', '#{@destination_cidr_block}', {'internetGatewayId' => '#{@internet_gateway_id}'})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].replace_route('rtb-00000000', @destination_cidr_block, {'internetGatewayId' => @internet_gateway_id})
    end
    tests("#replace_route('rtb-00000000', '#{@destination_cidr_block}')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].replace_route('rtb-00000000', @destination_cidr_block)
    end
    tests("#replace_route('#{@route_table_id}', '#{@destination_cidr_block}', {'gatewayId' => 'igw-00000000'})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].replace_route(@route_table_id, @destination_cidr_block, {'gatewayId' => 'igw-00000000'})
    end
    tests("#replace_route('rtb-00000000', '#{@destination_cidr_block}', {'instanceId' => '#{instance.id}'})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].replace_route('rtb-00000000', @destination_cidr_block, {'instanceId' => instance.id})
    end
    tests("#replace_route('#{@route_table_id}', '#{@destination_cidr_block}', {'instanceId' => 'i-00000000'})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].replace_route(@route_table_id, @destination_cidr_block, {'instanceId' => 'i-00000000'})
    end
    tests("#replace_route('#{@route_table_id}', '#{@destination_cidr_block}', {'networkInterfaceId' => 'eni-00000000'})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].replace_route(@route_table_id, @destination_cidr_block, {'networkInterfaceId' => 'eni-00000000'})
    end
    tests("#replace_route('rtb-00000000', '#{@destination_cidr_block}', {'networkInterfaceId' => '#{@network_interface_id}'})").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].replace_route('rtb-00000000', @destination_cidr_block, {'networkInterfaceId' => @network_interface_id})
    end
    if !Fog.mocking?
      tests("#replace_route less specific destination_cidr_block").raises(Fog::AWS::Compute::Error) do
        Fog::Compute[:aws].replace_route(@route_table_id, '10.0.10.0/25', {'gatewayId' => @internet_gateway_id})
      end
    end

    # Test describe_route_tables
    #   - passing a nonexisiting vpc
    #
    tests("#describe_route_tables('vpc-id' => 'vpc-00000000").formats({'routeTableSet'=>Array, 'requestId'=>String}) do
      Fog::Compute[:aws].describe_route_tables('vpc-id' => 'vpc-00000000').body
    end

    # Tests delete_route
    #   - no parameters
    #   - passing a nonexisiting route table
    #
    tests('#delete_route').raises(ArgumentError) do
      Fog::Compute[:aws].delete_route
    end
    tests("#delete_route('rtb-00000000', '#{@destination_cidr_block}')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].delete_route('rtb-00000000', @destination_cidr_block)
    end

    # Tests disassociate_route_table
    #   - no parameters
    #   - passing a nonexisiting route table association id
    #
    tests('#disassociate_route_table').raises(ArgumentError) do
      Fog::Compute[:aws].disassociate_route_table
    end
    tests("#disassociate_route_table('rtbassoc-00000000')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].disassociate_route_table('rtbassoc-00000000')
    end

    # Tests delete_route_table
    #   - no parameters
    #   - passing a nonexisiting route table
    #
    tests('#delete_route_table').raises(ArgumentError) do
      Fog::Compute[:aws].delete_route_table
    end
    tests("#delete_route_table('rtb-00000000')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].delete_route_table('rtb-00000000')
    end

    # Dependency Tests
    #   - route is depending on route_table, so route_table cannot be deleted
    #
    tests("#delete_route_table('#{@route_table_id}')").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].delete_route_table(@route_table_id)
    end

    Fog::Compute[:aws].servers.all('instance-id'=>instance.id).first.destroy
    if !Fog.mocking?
      instance.wait_for { state.eql? "terminated" }
    end
    Fog::Compute[:aws].delete_route(@route_table_id, @destination_cidr_block)
    Fog::Compute[:aws].disassociate_route_table(@association_id)
    Fog::Compute[:aws].delete_route_table(@route_table_id)
  end

  Fog::Compute[:aws].delete_network_interface(@network_interface_id)
  Fog::Compute[:aws].detach_internet_gateway(@internet_gateway_id, vpc.id)
  Fog::Compute[:aws].delete_internet_gateway(@internet_gateway_id)
  Fog::Compute[:aws].delete_subnet(@subnet_id)
  vpc.destroy
  key.destroy
end
