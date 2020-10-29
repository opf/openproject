Shindo.tests("Fog::AWS[:iam] | instance_profiles", ['aws', 'iam']) do
  model_tests(Fog::AWS[:iam].instance_profiles, {:name => uniq_id('fog-instance-profile')}) do
    @role = Fog::AWS[:iam].roles.create(:rolename => uniq_id('fog-role'))

    tests("#add_role('#{@role.rolename}')") do
      returns(true) { @instance.add_role(@role.rolename) }
    end

    returns(1) { @role.instance_profiles.count }
    returns(@instance) { @role.instance_profiles.first }

    tests("#remove_role('#{@role.rolename}')") do
      returns(true) { @instance.remove_role(@role.rolename) }
    end

    @role.destroy
  end
end
