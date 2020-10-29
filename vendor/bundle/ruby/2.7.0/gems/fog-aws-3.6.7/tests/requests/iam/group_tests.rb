Shindo.tests('AWS::IAM | group requests', ['aws']) do

  tests('success') do

    @group_format = {
      'Group' => {
        'Arn'       => String,
        'GroupId'   => String,
        'GroupName' => String,
        'Path'      => String
      },
      'RequestId' => String
    }

    tests("#create_group('fog_group')").formats(@group_format) do
      Fog::AWS[:iam].create_group('fog_group').body
    end

    @groups_format = {
      'Groups' => [{
        'Arn'       => String,
        'GroupId'   => String,
        'GroupName' => String,
        'Path'      => String
      }],
      'IsTruncated' => Fog::Boolean,
      'RequestId'   => String
    }

    tests("#list_groups").formats(@groups_format) do
      Fog::AWS[:iam].list_groups.body
    end

    tests("#delete_group('fog_group')").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].delete_group('fog_group').body
    end

  end

  tests('failure') do
    test('failing conditions')
  end

end
