Shindo.tests('AWS::IAM | role requests', ['aws']) do
  tests('success') do

    @role = {
        'Arn'                      => String,
        'AssumeRolePolicyDocument' => String,
        'CreateDate'               => Time,
        'Path'                     => String,
        'RoleId'                   => String,
        'RoleName'                 => String
      }
    @role_format = {
      'Role' => @role,
      'RequestId' => String
    }
    tests("#create_role('fogrole')").formats(@role_format) do
      Fog::AWS[:iam].create_role('fogrole', Fog::AWS::IAM::EC2_ASSUME_ROLE_POLICY).body
    end

    tests("#get_role('fogrole')").formats(@role_format) do
      Fog::AWS[:iam].get_role('fogrole').body
    end

    @list_roles_format = {
      'Roles'       => [@role],
      'RequestId'   => String,
      'IsTruncated' => Fog::Boolean,
    }

    tests("#list_roles").formats(@list_roles_format) do
      body = Fog::AWS[:iam].list_roles.body
      returns(true){!! body['Roles'].find {|role| role['RoleName'] == 'fogrole'}}
      body
    end

    @profile_format = {
      'InstanceProfile' => {
        'Arn'       => String,
        'CreateDate' => Time,
        'Path'      => String,
        'InstanceProfileId'    => String,
        'InstanceProfileName'  => String,
        'Roles' => [@role]
      },
      'RequestId' => String

    }
    tests("#create_instance_profile('fogprofile')").formats(@profile_format) do
      pending if Fog.mocking?
      Fog::AWS[:iam].create_instance_profile('fogprofile').body
    end

    tests("#get_instance_profile('fogprofile')").formats(@profile_format) do
      pending if Fog.mocking?
      Fog::AWS[:iam].get_instance_profile('fogprofile').body
    end

    tests("#add_role_to_instance_profile('fogprofile','fogrole')").formats(AWS::IAM::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:iam].add_role_to_instance_profile('fogrole', 'fogprofile').body
    end

    @profiles_format = {
      'InstanceProfiles' => [{
        'Arn'       => String,
        'CreateDate' => Time,
        'Path'      => String,
        'InstanceProfileId'    => String,
        'InstanceProfileName'  => String,
        'Roles' => [@role]
      }],
      'IsTruncated' => Fog::Boolean,
      'RequestId' => String

    }
    tests("list_instance_profiles_for_role('fogrole')").formats(@profiles_format) do
      pending if Fog.mocking?
      body = Fog::AWS[:iam].list_instance_profiles_for_role('fogrole').body
      returns(['fogprofile']) { body['InstanceProfiles'].map {|hash| hash['InstanceProfileName']}}
      body
    end

    tests("list_instance_profiles").formats(@profiles_format) do
      pending if Fog.mocking?
      Fog::AWS[:iam].list_instance_profiles.body
    end

    sample_policy = {"Statement" => [{"Effect" => "Allow", "Action" => "*", "Resource" => "*"}]}

    tests("put_role_policy").formats(AWS::IAM::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:iam].put_role_policy('fogrole', 'fogpolicy', sample_policy).body
    end

    @get_role_policy_format = {
      'Policy' => {
        'RoleName' => String,
        'PolicyName' => String,
        'PolicyDocument' => Hash,
      },
      'RequestId' => String
    }

    tests("get_role_policy").formats(@get_role_policy_format) do
      pending if Fog.mocking?
      body = Fog::AWS[:iam].get_role_policy('fogrole','fogpolicy').body
      returns('fogpolicy') {body['Policy']['PolicyName']}
      returns(sample_policy){body['Policy']['PolicyDocument']}
      body
    end

    @list_role_policies_format = {
      'PolicyNames' => [String],
      'IsTruncated' => Fog::Boolean,
      'RequestId' => String
    }

    tests("list_role_policies").formats(@list_role_policies_format) do
      pending if Fog.mocking?
      body = Fog::AWS[:iam].list_role_policies('fogrole').body

      returns(['fogpolicy']) {body['PolicyNames']}
      body
    end

    tests("delete_role_policy").formats(AWS::IAM::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:iam].delete_role_policy('fogrole', 'fogpolicy').body
    end

    returns([]) do
      pending if Fog.mocking?
      Fog::AWS[:iam].list_role_policies('fogrole').body['PolicyNames']
    end

    tests("remove_role_from_instance_profile").formats(AWS::IAM::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:iam].remove_role_from_instance_profile('fogrole', 'fogprofile').body
    end

    returns([]) do
      pending if Fog.mocking?
      Fog::AWS[:iam].list_instance_profiles_for_role('fogrole').body['InstanceProfiles']
    end

    tests("#delete_instance_profile('fogprofile'").formats(AWS::IAM::Formats::BASIC) do
      pending if Fog.mocking?
      Fog::AWS[:iam].delete_instance_profile('fogprofile').body
    end

    tests("#delete_role('fogrole'").formats(AWS::IAM::Formats::BASIC) do
      Fog::AWS[:iam].delete_role('fogrole').body
    end
  end

end
