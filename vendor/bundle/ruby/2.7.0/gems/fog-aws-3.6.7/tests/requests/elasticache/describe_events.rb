Shindo.tests('AWS::Elasticache | describe cache cluster events',
  ['aws', 'elasticache']) do

  tests('success') do
    pending if Fog.mocking?

    tests(
    '#describe_events'
    ).formats(AWS::Elasticache::Formats::EVENT_LIST) do
      Fog::AWS[:elasticache].describe_events().body['Events']
    end
  end

  tests('failure') do
    # TODO:
  end
end
