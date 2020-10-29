Shindo.tests('Fog::DNS[:aws] | DNS requests', ['aws', 'dns']) do

  pending if Fog.mocking?

  @r53_connection = Fog::DNS[:aws]

  tests('success') do

    tests('create a health check') do
      after do
        @r53_connection.delete_health_check(@response.body['HealthCheck']['Id'])
      end

      test('create an IP TCP based health check') do
        @response = @r53_connection.create_health_check('8.8.8.8', '53', 'TCP')
        @response.status == 201 &&
          @response.body['HealthCheck']['HealthCheckConfig']['IPAddress'] == '8.8.8.8' &&
          @response.body['HealthCheck']['HealthCheckConfig']['Port'] == '53'
      end

      test('create a FQDN HTTP based health check') do
        @options = {
          :fqdn => "www.amazon.com",
          :resource_path => "/gp/cart/view.html/ref=nav_cart"
        }
        @response = @r53_connection.create_health_check(nil, '80', 'HTTP', @options)
        @response.status == 201 &&
          @response.body['HealthCheck']['HealthCheckConfig']['IPAddress'].nil? &&
          @response.body['HealthCheck']['HealthCheckConfig']['Port'] == '80' &&
          @response.body['HealthCheck']['HealthCheckConfig']['FullyQualifiedDomainName'] == 'www.amazon.com'
      end
    end

    tests('get a health check') do
      @options = {
        :fqdn => "www.amazon.com",
        :resource_path => "/gp/cart/view.html/ref=nav_cart",
        :search_string => "Amazon",
        :request_interval => 10,
        :failure_threshold => "7"
      }
      create_response = @r53_connection.create_health_check('8.8.8.8', '443', 'HTTPS_STR_MATCH', @options)
      @health_check_id = create_response.body['HealthCheck']['Id']
      @response = @r53_connection.get_health_check(@health_check_id)

      sleep 2
      @r53_connection.delete_health_check(@health_check_id)

      test('id') do
        @response.body['HealthCheck']['Id'] == @health_check_id
      end

      {
        'IPAddress' => '8.8.8.8',
        'Port' => '443',
        'Type' => 'HTTPS_STR_MATCH',
        'FullyQualifiedDomainName' => @options[:fqdn],
        'ResourcePath' => @options[:resource_path],
        'RequestInterval' => @options[:request_interval],
        'FailureThreshold' => @options[:failure_threshold]
      }.each do |key, value|
        test("and check property #{key}") do
          @response.body['HealthCheck']['HealthCheckConfig'][key] == value
        end
      end
    end

    tests('delete a health check') do
      before do
        response = @r53_connection.create_health_check('8.8.8.8', '53', 'TCP')
        @health_check_id = response.body['HealthCheck']['Id']
      end

      test('setup as IP TCP') do
        response = @r53_connection.delete_health_check(@health_check_id)
        response.status == 200
      end
    end

    tests('listing health checks') do
      test('succeeds') do
        response = @r53_connection.list_health_checks
        response.status == 200
      end

      before do
        response_1 = @r53_connection.create_health_check('8.8.8.8', '53', 'TCP')
        @health_check_1_id = response_1.body['HealthCheck']['Id']
        options = {
          :fqdn => "www.amazon.com",
          :resource_path => "/gp/cart/view.html/ref=nav_cart"
        }
        response_2 = @r53_connection.create_health_check(nil, '80', 'HTTP', options)
        @health_check_2_id = response_2.body['HealthCheck']['Id']
        @health_check_ids = [@health_check_1_id, @health_check_2_id]
      end

      after do
        @health_check_ids.each { |id| @r53_connection.delete_health_check id }
      end

      test('contains 2 new health checks') do
        sleep 2
        response = @r53_connection.list_health_checks
        health_checks_by_id = response.body['HealthChecks'].map do |health_check|
          health_check['Id']
        end.to_a
        @health_check_ids.all? { |id| health_checks_by_id.include?(id) }
      end

      test('contains properties') do
        sleep 2
        response = @r53_connection.list_health_checks
        list_response_2 = response.body['HealthChecks'].find { |health_check| health_check['Id'] == @health_check_2_id }

        list_response_2['HealthCheckConfig']['Type'] == 'HTTP' &&
          list_response_2['HealthCheckConfig']['FullyQualifiedDomainName'] == 'www.amazon.com' &&
          list_response_2['HealthCheckConfig']['IPAddress'].nil?
      end
    end

    tests('assign a health check to a DNS record') do
      after do
        @r53_connection.change_resource_record_sets(@zone_id, [@resource_record.merge(:action => 'DELETE')])
        @r53_connection.delete_hosted_zone(@zone_id)
        @r53_connection.delete_health_check @health_check_id
      end

      health_check_response = @r53_connection.create_health_check('8.8.8.8', '53', 'TCP')
      raise "Health check was not created" unless health_check_response.status == 201
      @health_check_id = health_check_response.body['HealthCheck']['Id']

      @domain_name = generate_unique_domain
      zone_response = @r53_connection.create_hosted_zone(@domain_name)
      raise "Zone was not created for #{@domain_name}" unless zone_response.status == 201
      @zone_id = zone_response.body['HostedZone']['Id']

      @resource_record = {
        :name => "www.#{@domain_name}.",
        :type => 'A',
        :ttl => 3600,
        :resource_records => ['8.8.4.4'],
        :health_check_id => @health_check_id,
        :set_identifier => SecureRandom.hex(8),
        :weight => 50
      }
      resource_record_set = [@resource_record.merge(:action => 'CREATE')]
      record_response = @r53_connection.change_resource_record_sets @zone_id, resource_record_set
      raise "A record was not created" unless record_response.status == 200

      test('succeeds') do
        new_record = @r53_connection.list_resource_record_sets(@zone_id).body['ResourceRecordSets'].find do |record|
          record['Name'] == @resource_record[:name]
        end
        new_record['HealthCheckId'] == @health_check_id
      end
    end
  end
end
