Shindo.tests('Fog::Redshift[:aws] | cluster requests', ['aws']) do
  pending if Fog.mocking?
  identifier = "test-cluster-#{rand(65536).to_s(16)}"

  @cluster_format = {
    'Cluster' => {
      "ClusterParameterGroups"  => [{
        "ClusterParameterGroup" => {
          "ParameterApplyStatus"  => String,
          "ParameterGroupName"    => String
        }
      }],
      "ClusterSecurityGroups"  => [{
        'ClusterSecurityGroup' => {
          "Status"                   => String,
          "ClusterSecurityGroupName" => String
        }
      }],
      "VpcSecurityGroups"     => Fog::Nullable::Array,
      "EndPoint"              => Fog::Nullable::Hash,
      "PendingModifiedValues" => Fog::Nullable::Hash,
      "RestoreStatus"         => Fog::Nullable::Hash,
      "ClusterVersion"        => String,
      "ClusterStatus"         => String,
      "Encrypted"             => Fog::Boolean,
      "NumberOfNodes"         => Integer,
      "PubliclyAccessible"    => Fog::Boolean,
      "AutomatedSnapshotRetentionPeriod" => Integer,
      "DBName"                => String,
      "PreferredMaintenanceWindow" => String,
      "NodeType"              => String,
      "ClusterIdentifier"     => String,
      "AllowVersionUpgrade"   => Fog::Boolean,
      "MasterUsername"        => String
    }
  }
  @describe_clusters_format = {
    "ClusterSet" => [{
      'Cluster' => @cluster_format['Cluster'].merge({"ClusterCreateTime"=>Time, "AvailabilityZone"=>String, "EndPoint"=>{"Port"=>Integer, "Address"=>String}})
    }]
  }

  tests('success') do
    tests('create_cluster').formats(@cluster_format) do
      body = Fog::AWS[:redshift].create_cluster(:cluster_identifier   => identifier,
                                                :master_user_password => 'Password1234',
                                                :master_username      => 'testuser',
                                                :node_type            => 'dw.hs1.xlarge',
                                                :cluster_type         => 'single-node').body
      Fog.wait_for do
        "available" == Fog::AWS[:redshift].describe_clusters(:cluster_identifier=>identifier).body['ClusterSet'].first['Cluster']['ClusterStatus']
      end
      body
    end

    tests('describe_clusters').formats(@describe_clusters_format["ClusterSet"]) do
      sleep 30 unless Fog.mocking?
      body = Fog::AWS[:redshift].describe_clusters(:cluster_identifier=>identifier).body["ClusterSet"]
      body
    end

    tests('reboot_cluster') do
      sleep 30 unless Fog.mocking?
      body = Fog::AWS[:redshift].reboot_cluster(:cluster_identifier=>identifier).body
      tests("verify reboot").returns("rebooting") { body['Cluster']['ClusterStatus']}
      body
    end

    tests('delete_cluster') do
      Fog.wait_for do
        "available" == Fog::AWS[:redshift].describe_clusters(:cluster_identifier=>identifier).body['ClusterSet'].first['Cluster']['ClusterStatus']
      end
      sleep 30 unless Fog.mocking?
      body = Fog::AWS[:redshift].delete_cluster(:cluster_identifier=>identifier, :skip_final_cluster_snapshot=>true).body
      tests("verify delete").returns("deleting") { body['Cluster']['ClusterStatus']}
      body
    end
  end

end
