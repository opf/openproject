Shindo.tests('AWS::ECS | container instance requests', ['aws', 'ecs']) do

  Fog::AWS[:ecs].reset_data

  container_instance_arn = 'arn:aws:ecs:us-west-2:738152598183:container-instance/eff1068d-5fcb-4804-89f0-7d18ffc6879c'
  ec2_instance_id = 'i-58f4b4ae'

  Fog::AWS[:ecs].data[:container_instances] << {
    'remainingResources' => [
      {
        'longValue'    => 0,
        'name'         => 'CPU',
        'integerValue' => 1004,
        'doubleValue'  => 0.0,
        'type'         => 'INTEGER'
      },
      {
        'longValue'    => 0,
        'name'         => 'MEMORY',
        'integerValue' => 496,
        'doubleValue'  => 0.0,
        'type'         => 'INTEGER'
      },
      {
        'stringSetValue' => [2376, 22, 80, 51678, 2375],
        'longValue'      => 0,
        'name'           => 'PORTS',
        'integerValue'   => 0,
        'doubleValue'    => 0.0,
        'type'           => 'STRINGSET'
      }
    ],
    'agentConnected'      => true,                                               
    'runningTasksCount'   => 1,                                               
    'status'              => 'ACTIVE',                                                   
    'registeredResources' => [
      {
        'longValue'     => 0,
         'name'         => 'CPU',
         'integerValue' => 1024,
         'doubleValue'  => 0.0,
         'type'         => 'INTEGER'
      },
      {
        'longValue'     => 0,
        'name'          => 'MEMORY',
        'integerValue'  => 996,
        'doubleValue'   => 0.0,
        'type'          => 'INTEGER'
      },
      {
        'stringSetValue' => [2376, 22, 80, 51678, 2375],
        'longValue'      => 0,
        'name'           => 'PORTS',
        'integerValue'   => 0,
        'doubleValue'    => 0.0,
        'type'           => 'STRINGSET'
      }
    ],
    'containerInstanceArn' => container_instance_arn,
    'pendingTasksCount'    => 0,                                               
    'ec2InstanceId'        => ec2_instance_id
  }

  tests('success') do

    tests("#list_container_instances").formats(AWS::ECS::Formats::LIST_CONTAINER_INSTANCES) do
      result = Fog::AWS[:ecs].list_container_instances.body
      list_instances_arns = result['ListContainerInstancesResult']['containerInstanceArns']
      returns(false) { list_instances_arns.empty? }
      returns(true)  { list_instances_arns.first.eql?(container_instance_arn) }
      result
    end

    tests("#describe_container_instances").formats(AWS::ECS::Formats::DESCRIBE_CONTAINER_INSTANCES) do
      result = Fog::AWS[:ecs].describe_container_instances('containerInstances' => container_instance_arn).body
      instance = result['DescribeContainerInstancesResult']['containerInstances'].first
      returns(true) { instance['containerInstanceArn'].eql?(container_instance_arn) }
      returns(true) { instance['ec2InstanceId'].eql?(ec2_instance_id) }
      returns(true) { instance['status'].eql?('ACTIVE') }
      result
    end

    tests("#deregister_container_instance").formats(AWS::ECS::Formats::DEREGISTER_CONTAINER_INSTANCE) do
      result = Fog::AWS[:ecs].deregister_container_instance('containerInstance' => container_instance_arn).body
      instance = result['DeregisterContainerInstanceResult']['containerInstance']
      returns(true) { instance['containerInstanceArn'].eql?(container_instance_arn) }
      returns(true) { instance['ec2InstanceId'].eql?(ec2_instance_id) }
      returns(true) { instance['pendingTasksCount'].eql?(0) }
      result
    end

    tests("#list_container_instances again").formats(AWS::ECS::Formats::LIST_CONTAINER_INSTANCES) do
      result = Fog::AWS[:ecs].list_container_instances.body
      list_instances_arns = result['ListContainerInstancesResult']['containerInstanceArns']
      returns(true) { list_instances_arns.empty? }
      result
    end

  end

  tests('failures') do

    tests('#describe_container_instances without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].describe_container_instances.body
    end

    tests('#deregister_container_instance without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].deregister_container_instance.body
    end

    tests('#deregister_container_instance nonexistent').raises(Fog::AWS::ECS::Error) do
      instance_uuid = 'ffffffff-ffff-0000-ffff-deadbeefff'
      response = Fog::AWS[:ecs].deregister_container_instance('containerInstance' => instance_uuid).body
    end

  end

end
