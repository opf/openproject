Shindo.tests('AWS::ELB | load_balancer_tests', ['aws', 'elb']) do
  @load_balancer_id = 'fog-test-elb'
  @key_name = 'fog-test'

  tests('success') do
    if (Fog::AWS[:iam].get_server_certificate(@key_name) rescue nil)
      Fog::AWS[:iam].delete_server_certificate(@key_name)
    end

    @certificate = Fog::AWS[:iam].upload_server_certificate(AWS::IAM::SERVER_CERT, AWS::IAM::SERVER_CERT_PRIVATE_KEY, @key_name).body['Certificate']

    tests("#create_load_balancer").formats(AWS::ELB::Formats::CREATE_LOAD_BALANCER) do
      zones = ['us-east-1a']
      listeners = [{'LoadBalancerPort' => 80, 'InstancePort' => 80, 'InstanceProtocol' => 'HTTP', 'Protocol' => 'HTTP'}]
      Fog::AWS[:elb].create_load_balancer(zones, @load_balancer_id, listeners).body
    end

    tests("#describe_load_balancers").formats(AWS::ELB::Formats::DESCRIBE_LOAD_BALANCERS) do
      Fog::AWS[:elb].describe_load_balancers.body
    end

    tests('#describe_load_balancers with bad lb') do
      raises(Fog::AWS::ELB::NotFound) { Fog::AWS[:elb].describe_load_balancers('LoadBalancerNames' => 'none-such-lb') }
    end

    tests("#describe_load_balancers with SSL listener") do
      sleep 5 unless Fog.mocking?
      listeners = [
        {'Protocol' => 'HTTPS', 'LoadBalancerPort' => 443, 'InstancePort' => 443, 'SSLCertificateId' => @certificate['Arn']},
      ]
      Fog::AWS[:elb].create_load_balancer_listeners(@load_balancer_id, listeners)
      response = Fog::AWS[:elb].describe_load_balancers('LoadBalancerNames' => @load_balancer_id).body
      tests("SSLCertificateId is set").returns(@certificate['Arn']) do
        listeners = response["DescribeLoadBalancersResult"]["LoadBalancerDescriptions"].first["ListenerDescriptions"]
        listeners.find {|l| l["Listener"]["Protocol"] == 'HTTPS' }["Listener"]["SSLCertificateId"]
      end
    end

    tests("modify_load_balancer_attributes") do
      attributes = {
        'ConnectionDraining' => {'Enabled' => true, 'Timeout' => 600},
        'CrossZoneLoadBalancing' => {'Enabled' => true},
        'ConnectionSettings' => {'IdleTimeout' => 180}
      }
      Fog::AWS[:elb].modify_load_balancer_attributes(@load_balancer_id, attributes).body
      response = Fog::AWS[:elb].describe_load_balancer_attributes(@load_balancer_id).
        body['DescribeLoadBalancerAttributesResult']['LoadBalancerAttributes']

      tests("ConnectionDraining is enabled") do
        response['ConnectionDraining']['Enabled'] == true
      end
      tests("ConnectionDraining has a 600 second Timeout").returns(600) do
        response['ConnectionDraining']['Timeout']
      end
      tests("ConnectionSettings has a 180 second IdleTimeout").returns(180) do
        response['ConnectionSettings']['IdleTimeout']
      end
      tests("CrossZoneLoadBalancing is enabled") do
        response['CrossZoneLoadBalancing']['Enabled'] == true
      end
    end

    tests("#configure_health_check").formats(AWS::ELB::Formats::CONFIGURE_HEALTH_CHECK) do
      health_check = {
        'Target' => 'HTTP:80/index.html',
        'Interval' => 10,
        'Timeout' => 5,
        'UnhealthyThreshold' => 2,
        'HealthyThreshold' => 3
      }

      Fog::AWS[:elb].configure_health_check(@load_balancer_id, health_check).body
    end

    tests("#delete_load_balancer").formats(AWS::ELB::Formats::DELETE_LOAD_BALANCER) do
      Fog::AWS[:elb].delete_load_balancer(@load_balancer_id).body
    end

    tests("#delete_load_balancer when non existant").formats(AWS::ELB::Formats::DELETE_LOAD_BALANCER) do
      Fog::AWS[:elb].delete_load_balancer('non-existant').body
    end

    tests("#delete_load_balancer when already deleted").formats(AWS::ELB::Formats::DELETE_LOAD_BALANCER) do
      Fog::AWS[:elb].delete_load_balancer(@load_balancer_id).body
    end

    Fog::AWS[:iam].delete_server_certificate(@key_name)
  end
end
