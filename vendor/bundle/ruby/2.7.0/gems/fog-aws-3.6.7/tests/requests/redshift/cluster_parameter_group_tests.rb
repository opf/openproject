Shindo.tests('Fog::Redshift[:aws] | cluster parameter group requests', ['aws']) do
  pending if Fog.mocking?
  suffix = rand(65536).to_s(16)
  parameter_group = "test-cluster-parameter-group-#{suffix}"

  @cluster_parameter_format = {
    'Parameter' => {
      "ParameterValue" => String,
      "DataType"       => String,
      "Source"         => String,
      "IsModifiable"   => Fog::Boolean,
      "Description"    => String,
      "ParameterName"  => String
    }
  }

  @cluster_parameters_format = {
    "Parameters"=> [@cluster_parameter_format]
  }

  @cluster_parameter_group_format = {
    'ClusterParameterGroup' => {
      "ParameterGroupFamily" => String,
      "Description"          => String,
      "ParameterGroupName"   => String
    }
  }

  @cluster_parameter_groups_format = {
    "ParameterGroups"=> [@cluster_parameter_group_format]
  }

  @modify_cluster_parameter_group_format = {
    "ParameterGroupStatus" => String,
    "ParameterGroupName"   => String
  }

  tests('success') do
    tests("create_cluster_parameter_group").formats(@cluster_parameter_group_format) do
      body = Fog::AWS[:redshift].create_cluster_parameter_group(:parameter_group_name=> parameter_group,
                                                                :parameter_group_family=>"redshift-1.0",
                                                                :description=>'testing').body
      body
    end

    tests("describe_cluster_parameter_groups").formats(@cluster_parameter_groups_format) do
      body = Fog::AWS[:redshift].describe_cluster_parameter_groups.body
      body
    end

    tests("describe_cluster_parameters").formats(@cluster_parameters_format) do
      body = Fog::AWS[:redshift].describe_cluster_parameters(:parameter_group_name=>parameter_group).body
      body
    end

    tests("modify_cluster_parameter_groups").formats(@modify_cluster_parameter_group_format) do
      body = Fog::AWS[:redshift].modify_cluster_parameter_group(:parameter_group_name=>parameter_group,
                                                                :parameters=>{
                                                                   :parameter_name=>'extra_float_digits',
                                                                   :parameter_value=>2}).body
      body
    end

    tests("delete_cluster_parameter_group") do
      present = !Fog::AWS[:redshift].describe_cluster_parameter_groups(:parameter_group_name=>parameter_group).body['ParameterGroups'].empty?
      tests("verify presence before deletion").returns(true) { present }

      Fog::AWS[:redshift].delete_cluster_parameter_group(:parameter_group_name=>parameter_group)

      not_present = Fog::AWS[:redshift].describe_cluster_parameter_groups(:parameter_group_name=>parameter_group).body['ParameterGroups'].empty?
      tests("verify deletion").returns(true) { not_present }
     end

  end

end
