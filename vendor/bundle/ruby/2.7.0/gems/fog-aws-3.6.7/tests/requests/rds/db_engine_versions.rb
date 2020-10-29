Shindo.tests('AWS::RDS | describe db engine versions', ['aws', 'rds']) do
  tests('success') do
    tests("#describe_db_engine_versions").formats(AWS::RDS::Formats::DB_ENGINE_VERSIONS_LIST) do
      Fog::AWS[:rds].describe_db_engine_versions.body
    end
  end
end
