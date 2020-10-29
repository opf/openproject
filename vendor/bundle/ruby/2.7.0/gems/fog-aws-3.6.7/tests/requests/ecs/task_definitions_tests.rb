require 'fog/json'

Shindo.tests('AWS::ECS | task definitions requests', ['aws', 'ecs']) do

  Fog::AWS[:ecs].reset_data

  tests('success') do

    tests("#list_task_definitions").formats(AWS::ECS::Formats::LIST_TASK_DEFINITIONS) do
      result = Fog::AWS[:ecs].list_task_definitions.body
      list_task_def_arns = result['ListTaskDefinitionsResult']['taskDefinitionArns']
      returns(true) { list_task_def_arns.empty? }
      result
    end

    tests("#register_task_definition").formats(AWS::ECS::Formats::REGISTER_TASK_DEFINITION) do
      task_def_params = Fog::JSON.decode(IO.read(AWS::ECS::Samples::TASK_DEFINITION_1))
      result = Fog::AWS[:ecs].register_task_definition(task_def_params).body
      task_def = result['RegisterTaskDefinitionResult']['taskDefinition']
      returns('console-sample-app-static') { task_def['family'] }
      returns(true) { task_def['revision'] > 0 }
      returns(false) { task_def['taskDefinitionArn'].match(/^arn:aws:ecs:.+:.+:task-definition\/.+:\d+$/).nil? }
      result
    end

    tests("#list_task_definition_families").formats(AWS::ECS::Formats::LIST_TASK_DEFINITION_FAMILIES) do
      result = Fog::AWS[:ecs].list_task_definition_families.body
      families = result['ListTaskDefinitionFamiliesResult']['families']
      returns(false) { families.empty? }
      returns(true)  { families.include?('console-sample-app-static') }
      result
    end

    tests("#list_task_definitions again").formats(AWS::ECS::Formats::LIST_TASK_DEFINITIONS) do
      result = Fog::AWS[:ecs].list_task_definitions.body
      list_task_def_arns = result['ListTaskDefinitionsResult']['taskDefinitionArns']
      returns(true) { list_task_def_arns.size.eql?(1) }
      result
    end

    tests("#describe_task_definition").formats(AWS::ECS::Formats::DESCRIBE_TASK_DEFINITION) do
      result1 = Fog::AWS[:ecs].list_task_definitions.body
      task_def_arn = result1['ListTaskDefinitionsResult']['taskDefinitionArns'].first
      result2 = Fog::AWS[:ecs].describe_task_definition('taskDefinition' => task_def_arn).body
      task_def = result2['DescribeTaskDefinitionResult']['taskDefinition']
      returns(true) { task_def['taskDefinitionArn'].eql?(task_def_arn) }
      returns(true) { task_def['containerDefinitions'].size > 0 }
      result2
    end

    tests("#deregister_task_definition").formats(AWS::ECS::Formats::DEREGISTER_TASK_DEFINITION) do
      result1 = Fog::AWS[:ecs].list_task_definitions.body
      task_def_arn = result1['ListTaskDefinitionsResult']['taskDefinitionArns'].first
      result2 = Fog::AWS[:ecs].deregister_task_definition('taskDefinition' => task_def_arn).body
      task_def = result2['DeregisterTaskDefinitionResult']['taskDefinition']
      returns(true) { task_def['taskDefinitionArn'].eql?(task_def_arn) }
      result2
    end

    tests("#list_task_definitions yet again").formats(AWS::ECS::Formats::LIST_TASK_DEFINITIONS) do
      result = Fog::AWS[:ecs].list_task_definitions.body
      list_task_def_arns = result['ListTaskDefinitionsResult']['taskDefinitionArns']
      returns(true) { list_task_def_arns.empty? }
      result
    end

    tests("#list_task_definition_families again").formats(AWS::ECS::Formats::LIST_TASK_DEFINITION_FAMILIES) do
      result = Fog::AWS[:ecs].list_task_definition_families.body
      families = result['ListTaskDefinitionFamiliesResult']['families']
      returns(true)  { families.empty? }
      returns(false) { families.include?('console-sample-app-static') }
      result
    end

  end

  tests('failures') do

    tests('#describe_task_definition without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].describe_task_definition.body
    end

    tests('#describe_task_definition nonexistent').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].describe_task_definition('taskDefinition' => 'foobar').body
    end

    tests('#deregister_task_definition without params').raises(Fog::AWS::ECS::Error) do
      response = Fog::AWS[:ecs].deregister_task_definition.body
    end

    tests('#deregister_task_definition nonexistent').raises(Fog::AWS::ECS::NotFound) do
      response = Fog::AWS[:ecs].deregister_task_definition('taskDefinition' => 'foobar:7873287283').body
    end

  end

end
