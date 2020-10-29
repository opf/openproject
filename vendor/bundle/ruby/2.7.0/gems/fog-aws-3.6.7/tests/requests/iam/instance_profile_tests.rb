include AWS::IAM::Formats

Shindo.tests("AWS::IAM | instance profile requests", ['aws']) do
  tests('success') do
    profile_name = uniq_id('fog-instance-profile')
    @instance_profile_count = Fog::AWS[:iam].list_instance_profiles.body["InstanceProfiles"].count

    tests("#create_instance_profile('#{profile_name}')").formats(INSTANCE_PROFILE_RESULT) do
      Fog::AWS[:iam].create_instance_profile(profile_name).body
    end

    tests("#list_instance_profiles").formats(LIST_INSTANCE_PROFILE_RESULT) do
      body = Fog::AWS[:iam].list_instance_profiles.body
      returns(@instance_profile_count + 1) { body["InstanceProfiles"].count }
      body
    end

    tests("#get_instance_profile('#{profile_name}')").formats(INSTANCE_PROFILE_RESULT) do
      Fog::AWS[:iam].get_instance_profile(profile_name).body
    end

    @role = Fog::AWS[:iam].roles.create(:rolename => uniq_id('instance-profile-role'))

    tests("#add_role_to_instance_profile('#{@role.rolename}', '#{profile_name}')").formats(BASIC) do
      Fog::AWS[:iam].add_role_to_instance_profile(@role.rolename, profile_name).body
    end

    tests("#list_instance_profiles_for_role('#{@role.rolename}')").formats(LIST_INSTANCE_PROFILE_RESULT) do
      body = Fog::AWS[:iam].list_instance_profiles_for_role(@role.rolename).body
      returns(1) { body["InstanceProfiles"].count }
      body
    end

    tests("#remove_role_from_instance_profile('#{@role.rolename}', '#{profile_name}')").formats(BASIC) do
      Fog::AWS[:iam].remove_role_from_instance_profile(@role.rolename, profile_name).body
    end

    @role.destroy

    tests("#delete_instance_profile('#{profile_name}')").formats(BASIC) do
      Fog::AWS[:iam].delete_instance_profile(profile_name).body
    end
  end
end
