Shindo.tests('AWS::IAM | access key requests', ['aws']) do

  Fog::AWS[:iam].create_user('fog_access_key_tests')

  tests('success') do

    @access_key_format = {
      'AccessKey' => {
        'AccessKeyId'     => String,
        'UserName'        => String,
        'SecretAccessKey' => String,
        'Status'          => String
      },
      'RequestId' => String
    }

    tests("#create_access_key('UserName' => 'fog_access_key_tests')").formats(@access_key_format) do
      data = Fog::AWS[:iam].create_access_key('UserName' => 'fog_access_key_tests').body
      @access_key_id = data['AccessKey']['AccessKeyId']
      data
    end

    @access_keys_format = {
      'AccessKeys' => [{
        'AccessKeyId' => String,
        'Status'      => String
      }],
      'IsTruncated' => Fog::Boolean,
      'RequestId'   => String
    }

    tests("#list_access_keys('Username' => 'fog_access_key_tests')").formats(@access_keys_format) do
      Fog::AWS[:iam].list_access_keys('UserName' => 'fog_access_key_tests').body
    end

    tests("#update_access_key('#{@access_key_id}', 'Inactive', 'UserName' => 'fog_access_key_tests')").formats(AWS::IAM::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:iam].update_access_key(@access_key_id, 'Inactive', 'UserName' => 'fog_access_key_tests').body
    end

    tests("#delete_access_key('#{@access_key_id}', 'UserName' => 'fog_access_key_tests)").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].delete_access_key(@access_key_id, 'UserName' => 'fog_access_key_tests').body
    end

  end

  tests('failure') do
    test('failing conditions')
  end

  Fog::AWS[:iam].delete_user('fog_access_key_tests')

end
