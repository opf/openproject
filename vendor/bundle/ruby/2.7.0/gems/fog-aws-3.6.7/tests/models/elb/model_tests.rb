Shindo.tests('AWS::ELB | models', ['aws', 'elb']) do
  Fog::AWS::Compute::Mock.reset if Fog.mocking?
  @availability_zones = Fog::Compute[:aws].describe_availability_zones('state' => 'available').body['availabilityZoneInfo'].map{ |az| az['zoneName'] }
  @key_name = 'fog-test-model'
  @vpc = Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')
  @vpc_id = @vpc.id
  @subnet = Fog::Compute[:aws].subnets.create({:vpc_id => @vpc_id, :cidr_block => '10.0.10.0/24'})
  @subnet_id = @subnet.subnet_id
  @scheme = 'internal'
  @igw = Fog::Compute[:aws].internet_gateways.create
  @igw_id = @igw.id
  @igw.attach(@vpc_id)

  tests('success') do
    tests('load_balancers') do
      tests('getting a missing elb') do
        returns(nil) { Fog::AWS[:elb].load_balancers.get('no-such-elb') }
      end
    end

    tests('listeners') do
      tests("default attributes") do
        listener = Fog::AWS[:elb].listeners.new
        tests('instance_port is 80').returns(80) { listener.instance_port }
        tests('instance_protocol is HTTP').returns('HTTP') { listener.instance_protocol }
        tests('lb_port is 80').returns(80) { listener.lb_port }
        tests('protocol is HTTP').returns('HTTP') { listener.protocol }
        tests('policy_names is empty').returns([]) { listener.policy_names }
      end

      tests("specifying attributes") do
        attributes = {:instance_port => 2000, :instance_protocol => 'SSL', :lb_port => 2001, :protocol => 'SSL', :policy_names => ['fake'] }
        listener = Fog::AWS[:elb].listeners.new(attributes)
        tests('instance_port is 2000').returns(2000) { listener.instance_port }
        tests('instance_protocol is SSL').returns('SSL') { listener.instance_protocol }
        tests('lb_port is 2001').returns(2001) { listener.lb_port }
        tests('protocol is SSL').returns('SSL') { listener.protocol }
        tests('policy_names is [ fake ]').returns(['fake']) { listener.policy_names }
      end
    end

    elb = nil
    elb_id = 'fog-test'

    tests('create') do
      tests('without availability zones') do
        elb = Fog::AWS[:elb].load_balancers.create(:id => elb_id, :availability_zones => @availability_zones)
        tests("availability zones are correct").returns(@availability_zones.sort) { elb.availability_zones.sort }
        tests("dns names is set").returns(true) { elb.dns_name.is_a?(String) }
        tests("created_at is set").returns(true) { Time === elb.created_at }
        tests("policies is empty").returns([]) { elb.policies }
        tests("default listener") do
          tests("1 listener").returns(1) { elb.listeners.size }
          tests("params").returns(Fog::AWS[:elb].listeners.new.to_params) { elb.listeners.first.to_params }
        end
      end
      tests('with vpc') do
        elb2 = Fog::AWS[:elb].load_balancers.create(:id => "#{elb_id}-2", :subnet_ids => [@subnet_id])
        tests("elb source group should be default").returns('default') { elb2.source_group["GroupName"] }
        tests("subnet ids are correct").returns(@subnet_id) { elb2.subnet_ids.first }
        elb2.destroy
      end
      tests('with vpc internal') do
        elb2 = Fog::AWS[:elb].load_balancers.create(:id => "#{elb_id}-2", :subnet_ids => [@subnet_id], :scheme => 'internal')
        tests("scheme is internal").returns(@scheme) { elb2.scheme }
        elb2.destroy
      end
      tests('with default vpc') do
        Fog::Compute[:aws].disable_ec2_classic if Fog.mocking?

        if Fog::Compute[:aws].supported_platforms.include?("EC2")
          Fog::Formatador.display_line("[yellow]Skipping test [bold]with default vpc[/][yellow] due to AWS account having EC2 available[/]")
        else
          elb2 = Fog::AWS[:elb].load_balancers.create(:id => "#{elb_id}-2", :availability_zones => @availability_zones[0])
          tests("elb source group should start with default_elb_").returns(true) { !!(elb2.source_group["GroupName"] =~ /default_elb_/) }
          elb2.destroy
        end

        Fog::Compute[:aws].enable_ec2_classic if Fog.mocking?
      end

      if !Fog.mocking?
        @igw.detach(@vpc_id)
        @igw.destroy
        @subnet.destroy
        sleep 5
        @vpc.destroy
      end

      tests('with availability zones') do
        azs = @availability_zones[1..-1]
        elb2 = Fog::AWS[:elb].load_balancers.create(:id => "#{elb_id}-2", :availability_zones => azs)
        if Fog::Compute[:aws].supported_platforms.include?("EC2")
          tests("elb source group should be amazon-elb-sg").returns('amazon-elb-sg') { elb2.source_group["GroupName"] }
        else
          tests("elb source group should match default_elb_").returns(true) { !!(elb2.source_group["GroupName"] =~ /default_elb_/) }
        end
        tests("availability zones are correct").returns(azs.sort) { elb2.availability_zones.sort }
        elb2.destroy
      end

      # Need to sleep here for IAM changes to propgate
      tests('with ListenerDescriptions') do
        @certificate = Fog::AWS[:iam].upload_server_certificate(AWS::IAM::SERVER_CERT, AWS::IAM::SERVER_CERT_PRIVATE_KEY, @key_name).body['Certificate']
        sleep(10) unless Fog.mocking?
        listeners = [{
          'Listener' => {
            'LoadBalancerPort' => 2030, 'InstancePort' => 2030, 'Protocol' => 'HTTP'
          },
          'PolicyNames' => []
        }, {
          'Listener' => {
            'LoadBalancerPort' => 443, 'InstancePort' => 443, 'Protocol' => 'HTTPS', 'InstanceProtocol' => 'HTTPS',
            'SSLCertificateId' => @certificate['Arn']
          },
          'PolicyNames' => []
        }]
        elb3 = Fog::AWS[:elb].load_balancers.create(:id => "#{elb_id}-3", 'ListenerDescriptions' => listeners, :availability_zones => @availability_zones)
        tests('there are 2 listeners').returns(2) { elb3.listeners.count }
        tests('instance_port is 2030').returns(2030) { elb3.listeners.first.instance_port }
        tests('lb_port is 2030').returns(2030) { elb3.listeners.first.lb_port }
        tests('protocol is HTTP').returns('HTTP') { elb3.listeners.first.protocol }
        tests('protocol is HTTPS').returns('HTTPS') { elb3.listeners.last.protocol }
        tests('instance_protocol is HTTPS').returns('HTTPS') { elb3.listeners.last.instance_protocol }
        elb3.destroy
      end

      tests('with invalid Server Cert ARN').raises(Fog::AWS::IAM::NotFound) do
        listeners = [{
          'Listener' => {
            'LoadBalancerPort' => 443, 'InstancePort' => 80, 'Protocol' => 'HTTPS', 'InstanceProtocol' => 'HTTPS', "SSLCertificateId" => "fakecert"}
        }]
        Fog::AWS[:elb].load_balancers.create(:id => "#{elb_id}-4", "ListenerDescriptions" => listeners, :availability_zones => @availability_zones)
      end
    end

    tests('all') do
      elb_ids = Fog::AWS[:elb].load_balancers.all.map{|e| e.id}
      tests("contains elb").returns(true) { elb_ids.include? elb_id }
    end

    if Fog.mocking?
      tests('all marker support') do
        extra_elb_ids = (1..1000).map {|n| Fog::AWS[:elb].load_balancers.create(:id => "#{elb_id}-extra-#{n}").id }
        tests('returns all elbs').returns(true) { (extra_elb_ids - Fog::AWS[:elb].load_balancers.all.map {|e| e.id }).empty? }
      end
    end

    tests('get') do
      tests('ids match').returns(elb_id) { Fog::AWS[:elb].load_balancers.get(elb_id).id }
      tests('nil id').returns(nil) { Fog::AWS[:elb].load_balancers.get(nil) }
    end

    tests('creating a duplicate elb') do
      raises(Fog::AWS::ELB::IdentifierTaken) do
        Fog::AWS[:elb].load_balancers.create(:id => elb_id, :availability_zones => ['us-east-1d'])
      end
    end

    tests('registering an invalid instance') do
      raises(Fog::AWS::ELB::InvalidInstance) { elb.register_instances('i-00000000') }
    end

    tests('deregistering an invalid instance') do
      raises(Fog::AWS::ELB::InvalidInstance) { elb.deregister_instances('i-00000000') }
    end

    server = Fog::Compute[:aws].servers.create
    server.wait_for { ready? }

    tests('register instance') do
      begin
        elb.register_instances(server.id)
      rescue Fog::AWS::ELB::InvalidInstance
        # It may take a moment for a newly created instances to be visible to ELB requests
        raise if @retried_registered_instance
        @retried_registered_instance = true
        sleep 1
        retry
      end

      returns([server.id]) { elb.instances }
    end

    tests('instance_health') do
      returns('OutOfService') do
        elb.instance_health.find{|hash| hash['InstanceId'] == server.id}['State']
      end

      returns([server.id]) { elb.instances_out_of_service }
    end

    tests('deregister instance') do
      elb.deregister_instances(server.id)
      returns([]) { elb.instances }
    end
    server.destroy

    tests('disable_availability_zones') do
      elb.disable_availability_zones(@availability_zones[1..-1])
      returns(@availability_zones[0..0]) { elb.availability_zones.sort }
    end

    tests('enable_availability_zones') do
      elb.enable_availability_zones(@availability_zones[1..-1])
      returns(@availability_zones) { elb.availability_zones.sort }
    end

    tests('connection_draining') do
      returns(false) { elb.connection_draining? }
      returns(300) { elb.connection_draining_timeout }
      elb.set_connection_draining(true, 60)
      returns(true) { elb.connection_draining? }
      returns(60) { elb.connection_draining_timeout }
    end

    tests('cross_zone_load_balancing') do
      returns(false) {elb.cross_zone_load_balancing?}
      elb.cross_zone_load_balancing = true
      returns(true) {elb.cross_zone_load_balancing?}
    end

    tests('idle_connection_settings') do
      returns(60) { elb.connection_settings_idle_timeout }
      elb.set_connection_settings_idle_timeout(180)
      returns(180) { elb.connection_settings_idle_timeout }
    end

    tests('default health check') do
      default_health_check = {
        "HealthyThreshold"=>10,
        "Timeout"=>5,
        "UnhealthyThreshold"=>2,
        "Interval"=>30,
        "Target"=>"TCP:80"
      }
      returns(default_health_check) { elb.health_check }
    end

    tests('configure_health_check') do
      new_health_check = {
        "HealthyThreshold"=>5,
        "Timeout"=>10,
        "UnhealthyThreshold"=>3,
        "Interval"=>15,
        "Target"=>"HTTP:80/index.html"
      }
      elb.configure_health_check(new_health_check)
      returns(new_health_check) { elb.health_check }
    end

    tests('listeners') do
      tests('default') do
        returns(1) { elb.listeners.size }

        listener = elb.listeners.first
        returns([80,80,'HTTP','HTTP', []]) { [listener.instance_port, listener.lb_port, listener.protocol, listener.instance_protocol, listener.policy_names] }
      end

      tests('#get') do
        returns(80) { elb.listeners.get(80).lb_port }
      end

      tests('create') do
        elb.listeners.create(:instance_port => 443, :lb_port => 443, :protocol => 'TCP', :instance_protocol => 'TCP')
        returns(2) { elb.listeners.size }
        returns(443) { elb.listeners.get(443).lb_port }
      end

      tests('destroy') do
        elb.listeners.get(443).destroy
        returns(nil) { elb.listeners.get(443) }
      end
    end

    tests('policies') do
      app_policy_id = 'my-app-policy'

      tests 'are empty' do
        returns([]) { elb.policies.to_a }
      end

      tests('#all') do
        returns([]) { elb.policies.all.to_a }
      end

      tests('create app policy') do
        elb.policies.create(:id => app_policy_id, :cookie => 'my-app-cookie', :cookie_stickiness => :app)
        returns(app_policy_id) { elb.policies.first.id }
        returns("my-app-cookie") { elb.policies.get(app_policy_id).cookie }
      end

      tests('get policy') do
        returns(app_policy_id) { elb.policies.get(app_policy_id).id }
      end

      tests('destroy app policy') do
        elb.policies.first.destroy
        returns([]) { elb.policies.to_a }
      end

      lb_policy_id = 'my-lb-policy'
      tests('create lb policy') do
        elb.policies.create(:id => lb_policy_id, :expiration => 600, :cookie_stickiness => :lb)
        returns(lb_policy_id) { elb.policies.first.id }
      end

      tests('setting a listener policy') do
        elb.set_listener_policy(80, lb_policy_id)
        returns([lb_policy_id]) { elb.listeners.get(80).policy_names }
        returns(600) { elb.policies.get(lb_policy_id).expiration }
      end

      tests('unsetting a listener policy') do
        elb.unset_listener_policy(80)
        returns([]) { elb.listeners.get(80).policy_names }
      end

      public_key_policy_id = 'fog-public-key-policy'
      tests('create public key policy') do
        elb.policies.create(:id => public_key_policy_id, :type_name => 'PublicKeyPolicyType', :policy_attributes => {'PublicKey' => AWS::IAM::SERVER_CERT_PUBLIC_KEY})
        policy = elb.policies.get(public_key_policy_id)

        returns(public_key_policy_id) { policy.id }
        returns("PublicKeyPolicyType") { policy.type_name }
        returns(AWS::IAM::SERVER_CERT_PUBLIC_KEY) { policy.policy_attributes["PublicKey"] }
      end

      tests('a malformed policy') do
        raises(ArgumentError) { elb.policies.create(:id => 'foo', :cookie_stickiness => 'invalid stickiness') }
      end
    end

    tests('backend server descriptions') do
      tests('default') do
        returns(0) { elb.backend_server_descriptions.size }
      end

      tests('with a backend policy') do
        policy = "EnableProxyProtocol"
        port = 80
        elb.policies.create(:id => policy, :type_name => 'ProxyProtocolPolicyType', :policy_attributes => { "ProxyProtocol" => true })
        Fog::AWS[:elb].set_load_balancer_policies_for_backend_server(elb.id, port, [policy]).body
        elb.reload
        returns([policy]) { elb.backend_server_descriptions.get(port).policy_names }
      end
    end

    tests('setting a new ssl certificate id') do
      elb.listeners.create(:instance_port => 443, :lb_port => 443, :protocol => 'HTTPS', :instance_protocol => 'HTTPS', :ssl_id => @certificate['Arn'])
      elb.set_listener_ssl_certificate(443, @certificate['Arn'])
    end

    tests('destroy') do
      elb.destroy
    end

    Fog::AWS[:iam].delete_server_certificate(@key_name)
  end
end
