require 'fog/json'

Shindo.tests('AWS::ECS | task requests', ['aws', 'ecs']) do

  Fog::AWS[:ecs].reset_data

  tests('success') do

    tests("#list_tasks").formats(AWS::ECS::Formats::LIST_TASKS) do
      result = Fog::AWS[:ecs].list_tasks.body
      list_instances_arns = result['ListTasksResult']['taskArns']
      returns(true) { list_instances_arns.empty? }
      result
    end

    tests("#run_task").formats(AWS::ECS::Formats::RUN_TASK) do
      task_def_params = Fog::JSON.decode(IO.read(AWS::ECS::Samples::TASK_DEFINITION_1))
      result1 = Fog::AWS[:ecs].register_task_definition(task_def_params).body
      task_def = result1['RegisterTaskDefinitionResult']['taskDefinition']
      task_def_arn = task_def['taskDefinitionArn']

      result2 = Fog::AWS[:ecs].run_task('taskDefinition' => task_def_arn).body
      task = result2['RunTaskResult']['tasks'].first
      returns(true) { task.has_key?('containerInstanceArn') }
      returns(true) { task['containers'].size.eql?(2) }
      returns(true) { task['desiredStatus'].eql?('RUNNING') }
      returns(true) { task['taskDefinitionArn'].eql?(task_def_arn) }
      result2
    end

    tests("#describe_tasks").formats(AWS::ECS::Formats::DESCRIBE_TASKS) do
      result1 = Fog::AWS[:ecs].list_tasks.body
      task_arn = result1['ListTasksResult']['taskArns'].first

      result2 = Fog::AWS[:ecs].describe_tasks('tasks' => task_arn).body
      task = result2['DescribeTasksResult']['tasks'].first
      returns(true) { task['taskArn'].eql?(task_arn) }
      returns(true) { task['containers'].size.eql?(2) }
      returns(true) { task['desiredStatus'].eql?('RUNNING') }
      result2
    end

    tests("#list_tasks").formats(AWS::ECS::Formats::LIST_TASKS) do
      result = Fog::AWS[:ecs].list_tasks.body
      list_instances_arns = result['ListTasksResult']['taskArns']
      returns(false) { list_instances_arns.empty? }
      result
    end

    tests("#stop_task").formats(AWS::ECS::Formats::STOP_TASK) do
      result1 = Fog::AWS[:ecs].list_tasks.body
      task_arn = result1['ListTasksResult']['taskArns'].first

      result2 = Fog::AWS[:ecs].stop_task('task' => task_arn).body
      task = result2['StopTaskResult']['task']
      returns(true) { task['taskArn'].eql?(task_arn) }
      returns(true) { task['containers'].size.eql?(2) }
      returns(true) { task['desiredStatus'].eql?('STOPPED') }
      result2
    end

    tests("#start_task").formats(AWS::ECS::Formats::START_TASK) do
      owner_id = Fog::AWS::Mock.owner_id
      container_instance_path = "container-instance/#{Fog::UUID.uuid}"
      region = "us-east-1"
      container_instance_arn = Fog::AWS::Mock.arn('ecs', owner_id, container_instance_path, region)

      task_def_params = Fog::JSON.decode(IO.read(AWS::ECS::Samples::TASK_DEFINITION_1))
      result1 = Fog::AWS[:ecs].register_task_definition(task_def_params).body
      task_def = result1['RegisterTaskDefinitionResult']['taskDefinition']
      task_def_arn = task_def['taskDefinitionArn']

      result2 = Fog::AWS[:ecs].start_task(
        'taskDefinition' => task_def_arn,
        'containerInstances' => container_instance_arn
      ).body
      task = result2['StartTaskResult']['tasks'].first

      returns(true) { task['containerInstanceArn'].eql?(container_instance_arn) }
      returns(true) { task['containers'].size.eql?(2) }
      returns(true) { task['desiredStatus'].eql?('RUNNING') }
      returns(true) { task['taskDefinitionArn'].eql?(task_def_arn) }

      result2
    end

    tests("#list_tasks").formats(AWS::ECS::Formats::LIST_TASKS) do
      result = Fog::AWS[:ecs].list_tasks.body
      list_instances_arns = result['ListTasksResult']['taskArns']
      returns(false) { list_instances_arns.empty? }
      result
    end

  end

  tests('failures') do

    tests("#describe_tasks nonexistent") do
      task_arn = "arn:aws:ecs:us-west-2:938269302734:task/6893440f-2165-47aa-8cfa-b2f413a26f00"
      result = Fog::AWS[:ecs].describe_tasks('tasks' => task_arn).body
    end

    tests('describe_tasks without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].describe_tasks.body
    end

    tests('#run_task without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].run_task.body
    end

    tests('#run_task nonexistent').raises(Fog::AWS::ECS::Error) do
      task_def_arn = "arn:aws:ecs:us-west-2:539573770077:task-definition/foo-xanadu-app-static:33"
      response = Fog::AWS[:ecs].run_task('taskDefinition' => task_def_arn).body
    end

    tests('#start_task without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].start_task.body
    end

    tests('#start_task with missing params').raises(Fog::AWS::ECS::Error) do
      task_def_arn = "arn:aws:ecs:us-west-2:539573770077:task-definition/foo-xanadu-app-static:33"
      response = Fog::AWS[:ecs].start_task('taskDefinition' => task_def_arn).body
    end

    tests('#start_task nonexistent').raises(Fog::AWS::ECS::Error) do
      task_def_arn = "arn:aws:ecs:us-west-2:539573770077:task-definition/foo-xanadu-app-static:33"
      container_instance_arn = "arn:aws:ecs:us-west-2:938269302734:container-instance/6893440f-2165-47aa-8cfa-b2f413a26f00"
      response = Fog::AWS[:ecs].start_task(
        'taskDefinition' => task_def_arn,
        'containerInstances' => container_instance_arn
      ).body
    end

    tests('#stop_task without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].stop_task.body
    end

    tests('#stop_task nonexistent params').raises(Fog::AWS::ECS::Error) do
      task_arn = "arn:aws:ecs:us-west-2:938269302734:task/6893440f-2165-47aa-8cfa-b2f413a26f00"
      response = Fog::AWS[:ecs].stop_task('task' => task_arn).body
    end

  end

end
