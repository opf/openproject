Shindo.tests('Fog::Compute[:aws] | dhcp_options requests', ['aws']) do

  @dhcp_options_format = {
    'dhcpOptionsSet' => [{
      'dhcpOptionsId'            => String,
      'dhcpConfigurationSet'     => Hash,
      'tagSet'                   => Fog::Nullable::Hash,
    }],
    'requestId' => String
  }

  tests('success') do
    @vpc=Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')
    @vpc_id = @vpc.id

    tests('#create_dhcp_options').formats(@dhcp_options_format) do
      data = Fog::Compute[:aws].create_dhcp_options({'domain-name' => 'example.com', 'domain-name-servers' => '10.10.10.10'}).body
      @dopt_id = data['dhcpOptionsSet'].first['dhcpOptionsId']
      data
    end

    tests('#describe_dhcp_options').formats(@dhcp_options_format) do
      Fog::Compute[:aws].describe_dhcp_options.body
    end

    tests("#associate_dhcp_options('#{@dopt_id}, #{@vpc_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].associate_dhcp_options(@dopt_id, @vpc_id).body
    end

    tests("#associate_default_dhcp_options('default', #{@vpc_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].associate_dhcp_options('default', @vpc_id).body
    end

    tests("#delete_dhcp_options('#{@dopt_id}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_dhcp_options(@dopt_id).body
    end
    @vpc.destroy
  end
end
