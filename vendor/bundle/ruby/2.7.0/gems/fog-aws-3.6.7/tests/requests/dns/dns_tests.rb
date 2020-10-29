Shindo.tests('Fog::DNS[:aws] | DNS requests', ['aws', 'dns']) do

  @org_zone_count = 0
  @zone_id = ''
  @change_id = ''
  @new_records = []
  @domain_name = generate_unique_domain

  @elb_connection = Fog::AWS::ELB.new
  @r53_connection = Fog::DNS[:aws]

  tests('success') do

    test('get current zone count') do
      @org_zone_count= 0
      response = @r53_connection.list_hosted_zones
      if response.status == 200
        @hosted_zones = response.body['HostedZones']
        @org_zone_count = @hosted_zones.count
      end

      response.status == 200
    end

    test('create simple zone') {
      result = false

      response = @r53_connection.create_hosted_zone(@domain_name)
      if response.status == 201

        zone        = response.body['HostedZone']
        change_info = response.body['ChangeInfo']
        ns_servers  = response.body['NameServers']

        if (zone and change_info and ns_servers)

          @zone_id = zone['Id']
          caller_ref = zone['CallerReference']
          @change_id = change_info['Id']
          status = change_info['Status']
          ns_srv_count = ns_servers.count

          if (@zone_id.length > 0) and (caller_ref.length > 0) and (@change_id.length > 0) and
             (status.length > 0) and (ns_srv_count > 0)
            result = true
          end
        end
      end

      result
    }

    test("get status of change #{@change_id}") {
      result = false
      response = @r53_connection.get_change(@change_id)
      if response.status == 200
        status = response.body['Status']
        if (status == 'PENDING') or (status == 'INSYNC')
          result = true
        end
      end

      result
    }

    test("get info on hosted zone #{@zone_id}") {
      result = false

      response = @r53_connection.get_hosted_zone(@zone_id)
      if response.status == 200
        zone = response.body['HostedZone']
        zone_id = zone['Id']
        name = zone['Name']
        caller_ref = zone['CallerReference']
        ns_servers = response.body['NameServers']

        # AWS returns domain with a dot at end - so when compare, remove dot
        if (zone_id == @zone_id) and (name.chop == @domain_name) and (caller_ref.length > 0) and
           (ns_servers.count > 0)
           result = true
        end
      end

      result
    }

    test('list zones') do
      result = false

      response = @r53_connection.list_hosted_zones
      if response.status == 200

        zones= response.body['HostedZones']
        if (zones.count > 0)
          zone = zones[0]
          zone_id = zone['Id']
          zone_name= zone['Name']
          caller_ref = zone['CallerReference']
        end
        max_items = response.body['MaxItems']

        if (zone_id.length > 0) and (zone_name.length > 0) and (caller_ref.length > 0) and
           (max_items > 0)
          result = true
        end
      end

      result
    end

    test("add a A resource record") {
      # create an A resource record
      host = 'www.' + @domain_name
      ip_addrs = ['1.2.3.4']
      resource_record = { :name => host, :type => 'A', :ttl => 3600, :resource_records => ip_addrs }
      resource_record_set = resource_record.merge(:action => 'CREATE')

      change_batch = []
      change_batch << resource_record_set
      options = { :comment => 'add A record to domain'}
      response = @r53_connection.change_resource_record_sets(@zone_id, change_batch, options)

      Fog.wait_for { @r53_connection.get_change(response.body["Id"]).body["Status"] != "PENDING" }

      @new_records << resource_record

      @r53_connection.get_change(response.body["Id"]).body["Status"] == "INSYNC"
    }

    test("add a CNAME resource record") {
      # create a CNAME resource record
      host = 'mail.' + @domain_name
      value = ['www.' + @domain_name]
      resource_record = { :name => host, :type => 'CNAME', :ttl => 3600, :resource_records => value }
      resource_record_set = resource_record.merge(:action => 'CREATE')

      change_batch = []
      change_batch << resource_record_set
      options = { :comment => 'add CNAME record to domain'}
      response = @r53_connection.change_resource_record_sets( @zone_id, change_batch, options)

      Fog.wait_for { @r53_connection.get_change(response.body["Id"]).body["Status"] != "PENDING" }

      @new_records << resource_record

      @r53_connection.get_change(response.body["Id"]).body["Status"] == "INSYNC"
    }

    test("add a MX resource record") {
      # create a MX resource record
      host = @domain_name
      value = ['7 mail.' + @domain_name]
      resource_record = { :name => host, :type => 'MX', :ttl => 3600, :resource_records => value }
      resource_record_set = resource_record.merge( :action => 'CREATE')

      change_batch = []
      change_batch << resource_record_set
      options = { :comment => 'add MX record to domain'}
      response = @r53_connection.change_resource_record_sets( @zone_id, change_batch, options)

      Fog.wait_for { @r53_connection.get_change(response.body["Id"]).body["Status"] != "PENDING" }

      @new_records << resource_record

      @r53_connection.get_change(response.body["Id"]).body["Status"] == "INSYNC"
    }

    test("add an ALIAS resource record") {
      # create a load balancer
      @elb_connection.create_load_balancer(["us-east-1a"], "fog", [{"Protocol" => "HTTP", "LoadBalancerPort" => "80", "InstancePort" => "80"}])

      elb_response   = @elb_connection.describe_load_balancers("LoadBalancerNames" => "fog")
      elb            = elb_response.body["DescribeLoadBalancersResult"]["LoadBalancerDescriptions"].first
      hosted_zone_id = elb["CanonicalHostedZoneNameID"]
      dns_name       = elb["DNSName"]

      # create an ALIAS record
      host = @domain_name
      alias_target = {
        :hosted_zone_id         => hosted_zone_id,
        :dns_name               => dns_name,
        :evaluate_target_health => false
      }
      resource_record = { :name => host, :type => 'A', :alias_target => alias_target }
      resource_record_set = resource_record.merge(:action => 'CREATE')

      change_batch = []
      change_batch << resource_record_set
      options = { :comment => 'add ALIAS record to domain'}

      response = @r53_connection.change_resource_record_sets(@zone_id, change_batch, options)

      Fog.wait_for { @r53_connection.get_change(response.body["Id"]).body["Status"] != "PENDING" }

      @new_records << resource_record

      @r53_connection.get_change(response.body["Id"]).body["Status"] == "INSYNC"
    }


    tests("list resource records").formats(AWS::DNS::Formats::LIST_RESOURCE_RECORD_SETS)  {
      # get resource records for zone
      @r53_connection.list_resource_record_sets(@zone_id).body
    }

    test("delete #{@new_records.count} resource records") {
      change_batch = @new_records.map { |record| record.merge(:action => 'DELETE') }
      options      = { :comment => 'remove records from domain'}

      response = @r53_connection.change_resource_record_sets(@zone_id, change_batch, options)

      Fog.wait_for { @r53_connection.get_change(response.body["Id"]).body["Status"] != "PENDING" }

      @r53_connection.get_change(response.body["Id"]).body["Status"] == "INSYNC"
    }

    test("delete hosted zone #{@zone_id}") {
      # cleanup the ELB as well
      @elb_connection.delete_load_balancer("fog")

      @r53_connection.delete_hosted_zone(@zone_id).status == 200
    }

  end

  tests('failure') do
    tests('create hosted zone using invalid domain name').raises(Excon::Errors::BadRequest) do
      pending if Fog.mocking?
      @r53_connection.create_hosted_zone('invalid-domain')
    end

    tests('get hosted zone using invalid ID').raises(Excon::Errors::NotFound) do
      pending if Fog.mocking?
      zone_id = 'dummy-id'
      @r53_connection.get_hosted_zone(zone_id)
    end

  end

end
