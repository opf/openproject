Shindo.tests('AWS::ELB | listener_tests', ['aws', 'elb']) do
  @load_balancer_id = 'fog-test-listener'
  @key_name = 'fog-test'

  tests('success') do
    Fog::AWS[:elb].create_load_balancer(['us-east-1a'], @load_balancer_id, [{'LoadBalancerPort' => 80, 'InstancePort' => 80, 'Protocol' => 'HTTP'}])
    @certificate = Fog::AWS[:iam].upload_server_certificate(AWS::IAM::SERVER_CERT, AWS::IAM::SERVER_CERT_PRIVATE_KEY, @key_name).body['Certificate']

    tests("#create_load_balancer_listeners").formats(AWS::ELB::Formats::BASIC) do
      listeners = [
        {'Protocol' => 'TCP', 'InstanceProtocol' => 'TCP', 'LoadBalancerPort' => 443, 'InstancePort' => 443, 'SSLCertificateId' => @certificate['Arn']},
        {'Protocol' => 'HTTP', 'InstanceProtocol' => 'HTTP', 'LoadBalancerPort' => 80, 'InstancePort' => 80}
      ]
      response = Fog::AWS[:elb].create_load_balancer_listeners(@load_balancer_id, listeners).body
      response
    end

    tests("#delete_load_balancer_listeners").formats(AWS::ELB::Formats::BASIC) do
      ports = [80, 443]
      Fog::AWS[:elb].delete_load_balancer_listeners(@load_balancer_id, ports).body
    end

    tests("#create_load_balancer_listeners with non-existant SSL certificate") do
      listeners = [
        {'Protocol' => 'HTTPS', 'InstanceProtocol' => 'HTTPS', 'LoadBalancerPort' => 443, 'InstancePort' => 443, 'SSLCertificateId' => 'non-existant'},
      ]
      raises(Fog::AWS::IAM::NotFound) { Fog::AWS[:elb].create_load_balancer_listeners(@load_balancer_id, listeners) }
    end

    tests("#create_load_balancer_listeners with invalid SSL certificate").raises(Fog::AWS::IAM::NotFound) do
      sleep 8 unless Fog.mocking?
      listeners = [
        {'Protocol' => 'HTTPS', 'InstanceProtocol' => 'HTTPS', 'LoadBalancerPort' => 443, 'InstancePort' => 443, 'SSLCertificateId' => "#{@certificate['Arn']}fake"},
      ]
      Fog::AWS[:elb].create_load_balancer_listeners(@load_balancer_id, listeners).body
    end

    # This is sort of fucked up, but it may or may not fail, thanks AWS
    tests("#create_load_balancer_listeners with SSL certificate").formats(AWS::ELB::Formats::BASIC) do
      sleep 8 unless Fog.mocking?
      listeners = [
        {'Protocol' => 'HTTPS', 'InstanceProtocol' => 'HTTPS', 'LoadBalancerPort' => 443, 'InstancePort' => 443, 'SSLCertificateId' => @certificate['Arn']},
      ]
      Fog::AWS[:elb].create_load_balancer_listeners(@load_balancer_id, listeners).body
    end

    tests("#set_load_balancer_listener_ssl_certificate").formats(AWS::ELB::Formats::BASIC) do
      Fog::AWS[:elb].set_load_balancer_listener_ssl_certificate(@load_balancer_id, 443, @certificate['Arn']).body
    end

    tests("#create_load_balancer_listeners with invalid Protocol and InstanceProtocol configuration").raises(Fog::AWS::ELB::ValidationError) do
      listeners = [
        {'Protocol' => 'HTTP', 'InstanceProtocol' => 'TCP', 'LoadBalancerPort' => 80, 'InstancePort' => 80},
      ]
      Fog::AWS[:elb].create_load_balancer_listeners(@load_balancer_id, listeners).body
    end

    tests("#create_load_balancer_listeners with valid Protocol and InstanceProtocol configuration").formats(AWS::ELB::Formats::BASIC) do
      listeners = [
        {'Protocol' => 'HTTP', 'InstanceProtocol' => 'HTTPS', 'LoadBalancerPort' => 80, 'InstancePort' => 80},
      ]
      Fog::AWS[:elb].create_load_balancer_listeners(@load_balancer_id, listeners).body
    end

    Fog::AWS[:iam].delete_server_certificate(@key_name)
    Fog::AWS[:elb].delete_load_balancer(@load_balancer_id)
  end
end
