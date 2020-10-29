Shindo.tests('AWS::ECS | service requests', ['aws', 'ecs']) do

  Fog::AWS[:ecs].reset_data

  cluster = 'arn:aws:ecs:us-east-1:994922842243:cluster/default'
  desired_count = 1
  role = 'arn:aws:iam::806753142346:role/ecsServiceRole'
  service_name = 'sample-webapp'
  task_definition = 'console-sample-app-static:18'
  load_balancers = [{
    'containerName'    => 'simple-app',
    'containerPort'    => 80,
    'loadBalancerName' => 'ecsunittests-EcsElastic-OI09IAP3PVIP'
  }]

  tests('success') do

    tests("#list_services").formats(AWS::ECS::Formats::LIST_SERVICES) do
      result = Fog::AWS[:ecs].list_services('cluster' => cluster).body
      list_services_arns = result['ListServicesResult']['serviceArns']
      returns(true) { list_services_arns.empty? }
      result
    end

    tests("#create_service").formats(AWS::ECS::Formats::CREATE_SERVICE) do
      params = {
        'cluster'        => cluster,
        'desiredCount'   => desired_count,
        'loadBalancers'  => load_balancers,
        'role'           => role,
        'serviceName'    => service_name,
        'taskDefinition' => task_definition
      }
      result = Fog::AWS[:ecs].create_service(params).body
      service = result['CreateServiceResult']['service']
      returns('sample-webapp') { service['serviceName'] }
      returns(false) { service['serviceArn'].match(/^arn:aws:ecs:.+:.+:service\/.+$/).nil? }
      result
    end

    tests("#list_services again").formats(AWS::ECS::Formats::LIST_SERVICES) do
      result = Fog::AWS[:ecs].list_services('cluster' => cluster).body
      list_services_arns = result['ListServicesResult']['serviceArns']
      returns(false) { list_services_arns.empty? }
      returns(true)  { !list_services_arns.first.match(/#{service_name}/).nil? }
      result
    end

    tests("#describe_services").formats(AWS::ECS::Formats::DESCRIBE_SERVICES) do
      result1 = Fog::AWS[:ecs].list_services('cluster' => cluster).body
      service_arn = result1['ListServicesResult']['serviceArns'].first
      result2 = Fog::AWS[:ecs].describe_services(
        'services' => service_arn,
        'cluster' => cluster
      ).body
      returns(true) { result2['DescribeServicesResult']['services'].size.eql?(1) }
      service = result2['DescribeServicesResult']['services'].first
      returns(true)  { service['serviceName'].eql?(service_name) }
      returns(true)  { service['status'].eql?('ACTIVE') }
      returns(false) { service['deployments'].empty? }
      returns(true)  { service['desiredCount'].eql?(desired_count) }
      result2
    end

    tests("#update_service").formats(AWS::ECS::Formats::UPDATE_SERVICE) do
      new_task_def = 'arn:aws:ecs:us-east-1:994922842243:task-definitions/foobar-app:32'
      result1 = Fog::AWS[:ecs].list_services('cluster' => cluster).body
      service_arn = result1['ListServicesResult']['serviceArns'].first

      result2 = Fog::AWS[:ecs].update_service(
        'service' => service_arn,
        'cluster' => cluster,
        'taskDefinition' => new_task_def
      ).body
      service = result2['UpdateServiceResult']['service']
      returns(true) { service['serviceName'].eql?(service_name) }
      returns(true) { service['taskDefinition'].eql?(new_task_def) }
      result2
    end


    tests("#delete_service").formats(AWS::ECS::Formats::DELETE_SERVICE) do
      result1 = Fog::AWS[:ecs].list_services('cluster' => cluster).body
      service_arn = result1['ListServicesResult']['serviceArns'].first

      result2 = Fog::AWS[:ecs].delete_service(
        'service' => service_arn,
        'cluster' => cluster
      ).body
      service = result2['DeleteServiceResult']['service']
      returns(true) { service['serviceName'].eql?(service_name) }
      result2
    end

    tests("#list_services yet again").formats(AWS::ECS::Formats::LIST_SERVICES) do
      result = Fog::AWS[:ecs].list_services('cluster' => cluster).body
      list_services_arns = result['ListServicesResult']['serviceArns']
      returns(true) { list_services_arns.empty? }
      result
    end

  end

  tests('failures') do

    tests('#describe_services without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].describe_services.body
    end

    tests('#create_service without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].create_service.body
    end

    tests('#update_service without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].update_service.body
    end

    tests('#update_service nonexistent').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].update_service('service' => 'whatever2329').body
    end

    tests('#delete_service without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].delete_service.body
    end

    tests('#delete_service nonexistent').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].delete_service('service' => 'foobar787383').body
    end

  end

end
