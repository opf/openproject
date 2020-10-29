Shindo.tests('AWS::IAM | versioned managed policy requests', ['aws']) do

  pending if Fog.mocking?

  tests('success') do
    @policy = {'Version' => '2012-10-17', "Statement" => [{"Effect" => "Deny", "Action" => "*", "Resource" => "*"}]}
    @policy_v2 = {'Version' => '2012-10-17', "Statement" => [{"Effect" => "Allow", "Action" => "*", "Resource" => "*"}]}

    @policy_format = {
      'Arn'        => String,
      'AttachmentCount' => Integer,
      'Description' => String,
      'DefaultVersionId' => String,
      'IsAttachable' => Fog::Boolean,
      'Path'       => String,
      'PolicyId'     => String,
      'PolicyName'   => String,
      'CreateDate' => Time,
      'UpdateDate' => Time
    }

    create_policy_format = {
      'RequestId' => String,
      'Policy' => @policy_format
    }

    list_policies_format = {
      'RequestId' => String,
      'Policies' => [@policy_format],
      'Marker' => String,
      'IsTruncated' => Fog::Boolean      
    }

    versioned_policy_format = {
        'CreateDate' => Time,
        'Document' => Hash,
        'IsDefaultVersion' => Fog::Boolean,
        'Description' => String
    }

    create_versioned_policy_format = {
      'RequestId' => String,
      'PolicyVersion' => [versioned_policy_format]
    }

    policy_verions_format = {
        'CreateDate' => Time,
        'IsDefaultVersion' => Fog::Boolean,
        'VersionId' => String
    }

    list_policy_versions_format = {
      'RequestId' => String,
      'Versions' => [policy_verions_format],
      'Marker' => String,
      'IsTruncated' => Fog::Boolean      
    }

    tests("#create_policy('fog_policy')").formats(create_policy_format) do
      Fog::AWS[:iam].create_policy('fog_policy', @policy, '/fog/').body['Policy']['Arn']
    end

    tests("#list_policies('fog_policy')").formats(list_policies_format) do
      body = Fog::AWS[:iam].list_policies('PathPrefix' => '/fog/').body
      tests('length 1').returns(1) do
        body['Policies'].length
      end
      body
    end

    tests("#create_versioned_policy('fog_policy')").formats(create_versioned_policy_format) do
      Fog::AWS[:iam].create_versioned_policy(@policy_arn, @policy_v2, true).body['PolicyVersion']['Document']
    end

    tests("#list_policy_versions('fog_policy')").formats(list_policy_versions_format) do
      body = Fog::AWS[:iam].list_policy_versions(@policy_arn).body
      tests('length 2').returns(2) do
        body['Versions'].length
      end
      body
    end

    tests("#set_default_policy_version('fog_policy')").formats(AWS::IAM::Formats::BASIC) do
      body = Fog::AWS[:iam].set_default_policy_version(@policy_arn, 'v1').body
      tests('length 2').returns(2) do
        body['Versions'].length
      end
      body
    end

    tests("#delete_versioned_policy('fog_policy')").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].delete_policy(@policy_arn, 'v2').body['PolicyVersion']['Document']
    end

    tests("#delete_policy('fog_policy')").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].delete_policy(@policy_arn).body
    end
   
  end

  tests('failure') do
    test('failing conditions')
  end

end
