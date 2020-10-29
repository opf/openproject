Shindo.tests('AWS::STS | assume role with web identity', ['aws']) do
  @sts    = Fog::AWS[:sts]
  @iam    = Fog::AWS[:iam]
  @role   = @iam.create_role('sts', Fog::AWS::IAM::EC2_ASSUME_ROLE_POLICY).body['Role']
  @token  = Fog::AWS::Mock.key_id

  @response_format = {
    'AssumedRoleUser' => {
      'Arn'           => String,
      'AssumedRoleId' => String,
    },
    'Audience'    => String,
    'Credentials' => {
      'AccessKeyId'     => String,
      'Expiration'      => Time,
      'SecretAccessKey' => String,
      'SessionToken'    => String,
    },
    'Provider'                    => String,
    'SubjectFromWebIdentityToken' => String,
  }

  tests("#assume_role_with_web_identity('#{@role['Arn']}', '#{@token}', 'fog')").formats(@response_format) do
    @sts.assume_role_with_web_identity(@role['Arn'], @token, 'fog', :iam => @iam).body
  end

  @iam.roles.get('sts').destroy
end
