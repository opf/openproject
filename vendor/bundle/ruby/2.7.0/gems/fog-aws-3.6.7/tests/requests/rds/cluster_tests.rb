Shindo.tests('AWS::RDS | cluster requests', ['aws', 'rds']) do
  suffix = rand(65535).to_s(16)

  @cluster_id        = "fog-test-#{suffix}"
  @master_id         = "fog-master-#{suffix}"
  @final_snapshot_id = "fog-snapshot-#{suffix}"

  tests("success") do
    tests("#create_db_cluster").formats(AWS::RDS::Formats::CREATE_DB_CLUSTER) do
      result = Fog::AWS[:rds].create_db_cluster(@cluster_id,
                                                'Engine'             => 'aurora',
                                                'MasterUsername'     => "fog-#{suffix}",
                                                'MasterUserPassword' => "fog-#{suffix}"
                                               ).body

      cluster = result['CreateDBClusterResult']['DBCluster']
      returns("1")             { cluster['AllocatedStorage'] }
      returns('aurora')        { cluster['Engine'] }
      returns("fog-#{suffix}") { cluster['MasterUsername'] }
      result
    end

    tests("#describe_db_clusters").formats(AWS::RDS::Formats::DESCRIBE_DB_CLUSTERS) do
      Fog::AWS[:rds].describe_db_clusters.body
    end

    tests("#delete_db_cluster").formats(AWS::RDS::Formats::DELETE_DB_CLUSTER) do
      body = Fog::AWS[:rds].delete_db_cluster(@cluster_id, @final_snapshot_id).body

      tests('final snapshot') do
        returns('creating') { Fog::AWS[:rds].describe_db_cluster_snapshots(:snapshot_id => @final_snapshot_id).body['DescribeDBClusterSnapshotsResult']['DBClusterSnapshots'].first['Status'] }
      end

      body
    end
  end
end
