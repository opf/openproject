Shindo.tests("AWS::Support | describe_trusted_advisor_checks", ['aws', 'support']) do
  tests("#describe_trusted_advisor_checks").formats(AWS::Support::Formats::DESCRIBE_TRUSTED_ADVISOR_CHECKS) do
    Fog::AWS[:support].describe_trusted_advisor_checks.body
  end

  # things get weird in the mocked data depending on the order the model and requests run in
  if Fog.mocking?
    Fog::AWS[:support].reset
  end

  @check_id = Fog::AWS[:support].describe_trusted_advisor_checks.body['checks'].first['id']

  tests("#describe_trusted_advisor_check_result(id: #{@check_id})").formats(AWS::Support::Formats::DESCRIBE_TRUSTED_ADVISOR_CHECK_RESULT) do
    Fog::AWS[:support].describe_trusted_advisor_check_result(:id => @check_id).body
  end
end
