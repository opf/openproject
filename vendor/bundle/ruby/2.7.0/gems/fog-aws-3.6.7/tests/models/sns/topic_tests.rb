Shindo.tests("AWS::SNS | topic", ['aws', 'sns']) do
  params = {:id => 'fog'}

  model_tests(Fog::AWS[:sns].topics, params) do
    @instance.wait_for { ready? }

    tests("#display_name").returns('fog') { @instance.display_name }

    tests("#update_topic_attribute") do
      @instance.update_topic_attribute("DisplayName", "new-fog")

      tests("#display_name").returns('new-fog') { @instance.display_name }
    end
  end
end
