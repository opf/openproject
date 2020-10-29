Shindo.tests('Fog::Redshift[:aws] | cluster snapshot requests', ['aws']) do
  pending if Fog.mocking?
  suffix = rand(65536).to_s(16)
  identifier = "test-snapshot-#{suffix}"
  cluster    = "test-cluster-#{suffix}"
  start_time = Fog::Time.now.to_iso8601_basic
  @cluster_snapshot_format = {
    'Snapshot' => {
      "AccountsWithRestoreAccess"              => Fog::Nullable::Array,
      "Port"                                   => Integer,
      "SnapshotIdentifier"                     => String,
      "OwnerAccount"                           => String,
      "Status"                                 => String,
      "SnapshotType"                           => String,
      "ClusterVersion"                         => String,
      "EstimatedSecondsToCompletion"           => Integer,
      "SnapshotCreateTime"                     => Time,
      "Encrypted"                              => Fog::Boolean,
      "NumberOfNodes"                          => Integer,
      "DBName"                                 => String,
      "CurrentBackupRateInMegaBytesPerSecond"  => Float,
      "ClusterCreateTime"                      => Time,
      "AvailabilityZone"                       => String,
      "ActualIncrementalBackupSizeInMegaBytes" => Float,
      "TotalBackupSizeInMegaBytes"             => Float,
      "ElapsedTimeInSeconds"                   => Integer,
      "BackupProgressInMegaBytes"              => Float,
      "NodeType"                               => String,
      "ClusterIdentifier"                      => String,
      "MasterUsername"                         => String
    }
  }

  @describe_cluster_snapshots_format = {
    "Snapshots" => [@cluster_snapshot_format]
  }

  tests('success') do
    tests("create_cluster_snapshot").formats(@cluster_snapshot_format) do
      Fog::AWS[:redshift].create_cluster(:cluster_identifier   => cluster,
                                         :master_user_password => 'Pass1234',
                                         :master_username      => 'testuser',
                                         :node_type            => 'dw.hs1.xlarge',
                                         :cluster_type         => 'single-node')
      Fog.wait_for do
        "available" == Fog::AWS[:redshift].describe_clusters(:cluster_identifier=>cluster).body['ClusterSet'].first['Cluster']['ClusterStatus']
      end
      body = Fog::AWS[:redshift].create_cluster_snapshot(:snapshot_identifier => identifier,
                                                         :cluster_identifier  => cluster).body
      body
    end

    tests('describe_cluster_snaphots').formats(@describe_cluster_snapshots_format) do
      sleep 30 unless Fog.mocking?
      body = Fog::AWS[:redshift].describe_cluster_snapshots(:start_time=>start_time).body
      body
    end

    tests('delete_cluster_snapshot').formats(@cluster_snapshot_format) do
      Fog.wait_for do
        "available" == Fog::AWS[:redshift].describe_cluster_snapshots(:snapshot_identifier=>identifier).body['Snapshots'].first['Snapshot']['Status']
      end
      sleep 30 unless Fog.mocking?
      body = Fog::AWS[:redshift].delete_cluster_snapshot(:snapshot_identifier=>identifier).body
      body
    end

    Fog::AWS[:redshift].delete_cluster(:cluster_identifier          => cluster,
                                       :skip_final_cluster_snapshot => true)

  end

end
