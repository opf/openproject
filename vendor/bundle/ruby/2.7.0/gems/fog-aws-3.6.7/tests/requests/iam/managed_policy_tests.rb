Shindo.tests('AWS::IAM | managed policy requests', ['aws']) do

  Fog::AWS[:iam].create_group('fog_policy_test_group')
  Fog::AWS[:iam].create_user('fog_policy_test_user')
  Fog::AWS[:iam].create_role('fog_policy_test_role', Fog::AWS::IAM::EC2_ASSUME_ROLE_POLICY)

  tests('success') do
    @policy = {'Version' => '2012-10-17', "Statement" => [{"Effect" => "Deny", "Action" => "*", "Resource" => "*"}]}
    @policy_format = {
      'Arn'              => String,
      'AttachmentCount'  => Integer,
      'Description'      => Fog::Nullable::String,
      'DefaultVersionId' => String,
      'IsAttachable'     => Fog::Boolean,
      'Path'             => String,
      'PolicyId'         => String,
      'PolicyName'       => String,
      'CreateDate'       => Time,
      'UpdateDate'       => Time
    }

    create_policy_format = {
      'RequestId' => String,
      'Policy' => @policy_format
    }

    list_policies_format = {
      'RequestId' => String,
      'Policies' => [@policy_format],
      'Marker' => Fog::Nullable::String,
      'IsTruncated' => Fog::Boolean
    }

    attached_policy_format = {
        'PolicyArn' => String,
        'PolicyName' => String
    }

    list_managed_policies_format = {
        'RequestId' => String,
        'Policies' => [attached_policy_format]
    }

    tests("#create_policy('fog_policy')").formats(create_policy_format) do
      body = Fog::AWS[:iam].create_policy('fog_policy', @policy, '/fog/').body
      @policy_arn = body['Policy']['Arn']
      body
    end

    tests("#list_policies()").formats(list_policies_format) do
      body = Fog::AWS[:iam].list_policies('PathPrefix' => '/fog/').body
      tests('length 1').returns(1) do
        body['Policies'].length
      end
      body
    end


    tests("#attach_user_policy()").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].attach_user_policy('fog_policy_test_user', @policy_arn).body
    end

    tests("#list_attach_user_policies()").formats(list_managed_policies_format) do
      Fog::AWS[:iam].list_attached_user_policies('fog_policy_test_user').body
    end

    tests("#detach_user_policy()").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].detach_user_policy('fog_policy_test_user', @policy_arn).body
    end

    tests("#attach_group_policy()").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].attach_group_policy('fog_policy_test_group', @policy_arn).body
    end

    tests("#list_attach_group_policies()").formats(list_managed_policies_format) do
      Fog::AWS[:iam].list_attached_group_policies('fog_policy_test_group').body
    end

    tests("#detach_group_policy()").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].detach_group_policy('fog_policy_test_group', @policy_arn).body
    end

    tests("#attach_role_policy()").formats(AWS::IAM::Formats::BASIC) do
      body = Fog::AWS[:iam].attach_role_policy('fog_policy_test_role', @policy_arn).body
    end

    tests("#list_attached_role_policies()").formats(list_managed_policies_format) do
      Fog::AWS[:iam].list_attached_role_policies('fog_policy_test_role').body
    end

    tests("#detach_role_policy()").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].detach_role_policy('fog_policy_test_role', @policy_arn).body
    end

    tests("#delete_policy()").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].delete_policy(@policy_arn).body
    end

  end

  tests('failure') do
    test('failing conditions')
  end

  Fog::AWS[:iam].delete_group('fog_policy_test_group')
  Fog::AWS[:iam].delete_user('fog_policy_test_user')
  Fog::AWS[:iam].delete_role('fog_policy_test_role')


end
