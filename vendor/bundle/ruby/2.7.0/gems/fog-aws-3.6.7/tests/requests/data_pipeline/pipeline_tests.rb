Shindo.tests('AWS::DataPipeline | pipeline_tests', ['aws', 'data_pipeline']) do
  @pipeline_id = nil

  tests('success') do
    tests("#create_pipeline").formats(AWS::DataPipeline::Formats::BASIC) do
      unique_id = 'fog-test-pipeline-unique-id'
      name = 'fog-test-pipeline-name'
      description = 'Fog test pipeline'

      result = Fog::AWS[:data_pipeline].create_pipeline(unique_id, name, description, {}).body
      @pipeline_id = result['pipelineId']
      result
    end

    tests("#list_pipelines").formats(AWS::DataPipeline::Formats::LIST_PIPELINES) do
      Fog::AWS[:data_pipeline].list_pipelines.body
    end

    tests("#describe_pipelines").formats(AWS::DataPipeline::Formats::DESCRIBE_PIPELINES) do
      ids = [@pipeline_id]
      Fog::AWS[:data_pipeline].describe_pipelines(ids).body
    end

    tests("#put_pipeline_definition").formats(AWS::DataPipeline::Formats::PUT_PIPELINE_DEFINITION) do
      objects = [
        {
          "id" => "Nightly",
          "type" => "Schedule",
          "startDateTime" => Time.now.strftime("%Y-%m-%dT%H:%M:%S"),
          "period" => "24 hours",
        },
        {
          "id" => "Default",
          "role" => "role-dumps",
          "resourceRole" => "role-dumps-inst",
          "schedule" => { "ref" => "Nightly" },
        },
      ]

      Fog::AWS[:data_pipeline].put_pipeline_definition(@pipeline_id, objects).body
    end

    tests("#activate_pipeline") do
      Fog::AWS[:data_pipeline].activate_pipeline(@pipeline_id)
    end

    tests("#deactivate_pipeline") do
      Fog::AWS[:data_pipeline].activate_pipeline(@pipeline_id)
    end

    tests("#get_pipeline_definition").formats(AWS::DataPipeline::Formats::GET_PIPELINE_DEFINITION) do
      Fog::AWS[:data_pipeline].get_pipeline_definition(@pipeline_id).body
    end

    tests("#query_objects") do
      tests("for COMPONENTs").formats(AWS::DataPipeline::Formats::QUERY_OBJECTS) do
        Fog::AWS[:data_pipeline].query_objects(@pipeline_id, 'COMPONENT').body
      end

      tests("for INSTANCEs").formats(AWS::DataPipeline::Formats::QUERY_OBJECTS) do
        Fog::AWS[:data_pipeline].query_objects(@pipeline_id, 'INSTANCE').body
      end

      tests("for ATTEMPTs").formats(AWS::DataPipeline::Formats::QUERY_OBJECTS) do
        Fog::AWS[:data_pipeline].query_objects(@pipeline_id, 'ATTEMPT').body
      end
    end

    tests('#describe_objects').formats(AWS::DataPipeline::Formats::DESCRIBE_OBJECTS) do
      attempts = Fog::AWS[:data_pipeline].query_objects(@pipeline_id, 'ATTEMPT').body
      object_ids = attempts['ids'][0..5]
      Fog::AWS[:data_pipeline].describe_objects(@pipeline_id, object_ids).body
    end

    tests("#delete_pipeline").returns(true) do
      Fog::AWS[:data_pipeline].delete_pipeline(@pipeline_id)
    end

  end
end
