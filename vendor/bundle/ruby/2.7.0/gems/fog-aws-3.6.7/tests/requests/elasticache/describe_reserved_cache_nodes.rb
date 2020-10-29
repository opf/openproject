Shindo.tests('AWS::Elasticache | describe reserved cache nodes',
  ['aws', 'elasticache']) do

  tests('success') do
    pending if Fog.mocking?

    tests(
    '#describe_reserved_cache_nodes'
    ).formats(AWS::Elasticache::Formats::RESERVED_CACHE_NODES) do
      Fog::AWS[:elasticache].describe_reserved_cache_nodes().body['ReservedCacheNodes']
    end
  end

  tests('failure') do
    # TODO:
  end
end
