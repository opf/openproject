Shindo.tests('AWS::IAM | user requests', ['aws']) do
  service = Fog::AWS[:iam]

  begin
    service.delete_group('fog_user_tests')
  rescue Fog::AWS::IAM::NotFound
  end

  begin
    service.delete_user('fog_user').body
  rescue Fog::AWS::IAM::NotFound
  end

  username = 'fog_user'

  service.create_group('fog_user_tests')

  tests("#create_user('#{username}')").data_matches_schema(AWS::IAM::Formats::CREATE_USER) do
    service.create_user(username).body
  end

  tests("#list_users").data_matches_schema(AWS::IAM::Formats::LIST_USER) do
    service.list_users.body
  end

  tests("#get_user('#{username}')").data_matches_schema(AWS::IAM::Formats::GET_USER) do
    service.get_user(username).body
  end

  tests("#get_user").data_matches_schema(AWS::IAM::Formats::GET_CURRENT_USER) do
    body = Fog::AWS[:iam].get_user.body
    if Fog.mocking?
      tests("correct root arn").returns(true) {
        body["User"]["Arn"].end_with?(":root")
      }
    end

    body
  end

  tests("#create_login_profile") do
    service.create_login_profile(username, SecureRandom.base64(10))
  end

  tests("#get_login_profile") do
    service.get_login_profile(username)
  end

  tests("#update_login_profile") do
    # avoids Fog::AWS::IAM::Error: EntityTemporarilyUnmodifiable => Login Profile for User instance cannot be modified while login profile is being created.
    if Fog.mocking?
      service.update_login_profile(username, SecureRandom.base64(10))
    end
  end

  tests("#delete_login_profile") do
    service.delete_login_profile(username)
  end

  tests("#add_user_to_group('fog_user_tests', '#{username}')").data_matches_schema(AWS::IAM::Formats::BASIC) do
    service.add_user_to_group('fog_user_tests', username).body
  end

  tests("#list_groups_for_user('#{username}')").data_matches_schema(AWS::IAM::Formats::GROUPS) do
    service.list_groups_for_user(username).body
  end

  tests("#remove_user_from_group('fog_user_tests', '#{username}')").data_matches_schema(AWS::IAM::Formats::BASIC) do
    service.remove_user_from_group('fog_user_tests', username).body
  end

  tests("#delete_user('#{username}')").data_matches_schema(AWS::IAM::Formats::BASIC) do
    service.delete_user(username).body
  end

  service.delete_group('fog_user_tests')

end
