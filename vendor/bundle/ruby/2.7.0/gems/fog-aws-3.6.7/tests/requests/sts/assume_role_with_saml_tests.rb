Shindo.tests('AWS::STS | assume role with SAML', ['aws']) do

  @policy = {"Statement" => [{"Effect" => "Allow", "Action" => "*", "Resource" => "*"}]}

  @response_format = {
    'SessionToken'    => String,
    'SecretAccessKey' => String,
    'Expiration'      => String,
    'AccessKeyId'     => String,
    'Arn'             => String,
    'RequestId'       => String
  }

  tests("#assume_role_with_saml('role_arn', 'principal_arn', 'saml_assertion', #{@policy.inspect}, 900)").formats(@response_format) do
    pending if Fog.mocking?
    Fog::AWS[:sts].assume_role_with_saml("role_arn","principal_arn","saml_assertion", @policy, 900).body
  end
end
