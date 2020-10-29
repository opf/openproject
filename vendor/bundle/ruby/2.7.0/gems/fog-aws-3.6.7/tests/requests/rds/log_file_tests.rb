Shindo.tests('AWS::RDS | log file requests', %w[aws rds]) do
  tests('success') do
    pending if Fog.mocking?

    suffix = rand(65536).to_s(16)
    @db_instance_id = "fog-test-#{suffix}"

    tests('#describe_db_log_files').formats(AWS::RDS::Formats::DESCRIBE_DB_LOG_FILES) do
      result = Fog::AWS[:rds].describe_db_log_files(@db_instance_id).body['DescribeDBLogFilesResult']
      returns(true) { result['DBLogFiles'].size > 0 }
      result
    end

  end

  tests('failures') do
    raises(Fog::AWS::RDS::NotFound) {Fog::AWS[:rds].describe_db_log_files('doesntexist')}
  end
end
