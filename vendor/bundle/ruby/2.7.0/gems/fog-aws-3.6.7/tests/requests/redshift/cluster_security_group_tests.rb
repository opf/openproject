Shindo.tests('Fog::Redshift[:aws] | cluster security group requests', ['aws']) do
  pending if Fog.mocking?
  suffix     = rand(65536).to_s(16)
  identifier = "test-cluster-security-group-#{suffix}"

  @cluster_security_group_format = {
    "ClusterSecurityGroup"  => {
      "EC2SecurityGroups"        => Fog::Nullable::Array,
      "IPRanges"                 => Fog::Nullable::Array,
      "Description"              => String,
      "ClusterSecurityGroupName" => String
    }
  }

  @describe_cluster_security_groups_format = {
    "ClusterSecurityGroups" => [@cluster_security_group_format]
  }

  tests('success') do
    tests("create_cluster_security_group").formats(@cluster_security_group_format) do
      body = Fog::AWS[:redshift].create_cluster_security_group(:cluster_security_group_name => identifier, :description => 'testing').body
      body
    end

    tests("describe_cluster_security_groups").formats(@describe_cluster_security_groups_format) do
      body = Fog::AWS[:redshift].describe_cluster_security_groups.body
      body
    end

    tests("delete_cluster_security_group") do
      present = !Fog::AWS[:redshift].describe_cluster_security_groups(:cluster_security_group_name => identifier).body['ClusterSecurityGroups'].empty?
      tests("verify presence before deletion").returns(true) { present }

      Fog::AWS[:redshift].delete_cluster_security_group(:cluster_security_group_name => identifier)

      not_present = Fog::AWS[:redshift].describe_cluster_security_groups(:cluster_security_group_name => identifier).body['ClusterSecurityGroups'].empty?
      tests("verify deletion").returns(true) { not_present }
    end

  end

end
