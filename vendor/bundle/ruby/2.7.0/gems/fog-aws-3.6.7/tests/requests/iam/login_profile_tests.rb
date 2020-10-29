Shindo.tests('AWS::IAM | user requests', ['aws']) do

  unless Fog.mocking?
    Fog::AWS[:iam].create_user('fog_user')
  end

  tests('success') do
    @login_profile_format = {
      'LoginProfile' => {
        'UserName'  => String,
        'CreateDate'  => Time

      },
      'RequestId' => String
    }

    tests("#create_login_profile('fog_user')").formats(@login_profile_format) do
      pending if Fog.mocking?
      Fog::AWS[:iam].create_login_profile('fog_user', 'somepassword').body
    end

    tests("#get_login_profile('fog_user')").formats(@login_profile_format) do
      pending if Fog.mocking?
      result = Fog::AWS[:iam].get_login_profile('fog_user').body
      returns('fog_user') {result['LoginProfile']['UserName']}
      result
    end

    tests("#update_login_profile('fog_user')").formats(AWS::IAM::Formats::BASIC) do
      pending if Fog.mocking?
      begin
        Fog::AWS[:iam].update_login_profile('fog_user', 'otherpassword').body
      rescue Excon::Errors::Conflict #profile cannot be updated or deleted until it has finished creating; api provides no way of telling whether creation process complete
        sleep 5
        retry
      end
    end

    tests("#delete_login_profile('fog_user')").formats(AWS::IAM::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:iam].delete_login_profile('fog_user').body
    end

    tests("#get_login_profile('fog_user')") do
      pending if Fog.mocking?
      raises(Excon::Errors::NotFound) {Fog::AWS[:iam].get_login_profile('fog_user')}
    end

  end

  tests('failure') do
    tests('get login profile for non existing user') do
      pending if Fog.mocking?
      raises(Fog::AWS::IAM::NotFound) { Fog::AWS[:iam].get_login_profile('idontexist')}
      raises(Fog::AWS::IAM::NotFound) { Fog::AWS[:iam].delete_login_profile('fog_user')}
    end
  end

  unless Fog.mocking?
    Fog::AWS[:iam].delete_user('fog_user')
  end
end
