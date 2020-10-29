Shindo.tests('AWS::STS | assume role', ['aws']) do

  @policy = {"Statement" => [{"Effect" => "Allow", "Action" => "*", "Resource" => "*"}]}

  @response_format = {
    'SessionToken' => String,
    'SecretAccessKey' => String,
    'Expiration' => String,
    'AccessKeyId' => String,
    'Arn' => String,
    'RequestId' => String
  }

  tests("#assume_role('rolename', 'assumed_role_session', 'external_id', #{@policy.inspect}, 900)").formats(@response_format) do
    pending if Fog.mocking?
    Fog::AWS[:sts].assume_role("rolename","assumed_role_session","external_id", @policy, 900).body
  end

end
