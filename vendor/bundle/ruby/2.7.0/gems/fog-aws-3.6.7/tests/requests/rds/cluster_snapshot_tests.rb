Shindo.tests('AWS::RDS | cluster snapshot requests', ['aws', 'rds']) do
  @cluster_id     = uniq_id("fog-test")
  @snapshot_id    = uniq_id("cluster-db-snapshot")
  @cluster        = Fog::AWS[:rds].clusters.create(rds_default_cluster_params.merge(:id => @cluster_id))
  @snapshot_count = Fog::AWS[:rds].describe_db_cluster_snapshots.body['DescribeDBClusterSnapshotsResult']['DBClusterSnapshots'].count

  tests("success") do
    tests("#create_db_cluster_snapshot").formats(AWS::RDS::Formats::CREATE_DB_CLUSTER_SNAPSHOT) do
      result = Fog::AWS[:rds].create_db_cluster_snapshot(@cluster_id, @snapshot_id).body

      snapshot = result['CreateDBClusterSnapshotResult']['DBClusterSnapshot']
      returns(@snapshot_id)               { snapshot["DBClusterSnapshotIdentifier"] }
      returns(@cluster.engine)            { snapshot["Engine"] }
      returns(@cluster.id)                { snapshot["DBClusterIdentifier"] }
      returns(@cluster.engine_version)    { snapshot["EngineVersion"] }
      returns(@cluster.allocated_storage) { snapshot["AllocatedStorage"].to_i }
      returns(@cluster.master_username)   { snapshot["MasterUsername"] }

      result
    end

    second_snapshot = Fog::AWS[:rds].create_db_cluster_snapshot(@cluster_id, uniq_id("second-snapshot")).body['CreateDBClusterSnapshotResult']['DBClusterSnapshot']

    tests("#describe_db_cluster_snapshots").formats(AWS::RDS::Formats::DESCRIBE_DB_CLUSTER_SNAPSHOTS) do
      result    = Fog::AWS[:rds].describe_db_cluster_snapshots.body
      snapshots = result['DescribeDBClusterSnapshotsResult']['DBClusterSnapshots']
      returns(@snapshot_count + 2) { snapshots.count }

      single_result = Fog::AWS[:rds].describe_db_cluster_snapshots(:snapshot_id => second_snapshot['DBClusterSnapshotIdentifier']).body['DescribeDBClusterSnapshotsResult']['DBClusterSnapshots']
      returns([second_snapshot['DBClusterSnapshotIdentifier']]) { single_result.map { |s| s['DBClusterSnapshotIdentifier'] } }

      result
    end

    tests("delete_db_cluster_snapshot").formats(AWS::RDS::Formats::DELETE_DB_CLUSTER_SNAPSHOT) do
      result = Fog::AWS[:rds].delete_db_cluster_snapshot(@snapshot_id).body

      raises(Fog::AWS::RDS::NotFound) { Fog::AWS[:rds].describe_db_cluster_snapshots(:snapshot_id => @snapshot_id) }

      result
    end
  end
end
