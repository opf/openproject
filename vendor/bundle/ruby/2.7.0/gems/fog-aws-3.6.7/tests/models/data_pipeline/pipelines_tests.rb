Shindo.tests("AWS::DataPipeline | pipelines", ['aws', 'data_pipeline']) do
  pending if Fog.mocking?

  unique_id = uniq_id
  collection_tests(Fog::AWS[:data_pipeline].pipelines, { :id => unique_id, :name => "#{unique_id}-name", :unique_id => unique_id }) do
    @instance.wait_for { state }
  end
end
