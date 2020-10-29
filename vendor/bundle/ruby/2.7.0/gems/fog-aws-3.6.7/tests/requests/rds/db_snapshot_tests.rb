Shindo.tests('Fog::Rds[:aws] | db snapshot requests', ['aws']) do

  @snapshot_format = {
    'AllocatedStorage'     => Integer,
    'AvailabilityZone'     => Fog::Nullable::String,
    'Engine'               => String,
    'EngineVersion'        => String,
    'InstanceCreateTime'   => Time,
    'DBInstanceIdentifier' => String,
    'DBSnapshotIdentifier' => String,
    'Iops'                 => Fog::Nullable::Integer,
    'MasterUsername'       => String,
    'Port'                 => Fog::Nullable::Integer,
    'Status'               => String,
    'StorageType'          => String,
    'SnapshotType'         => String,
    'SnapshotCreateTime' => Fog::Nullable::Time,
  }

  @snapshots_format = {
    'requestId'   => String
  }

  @rds_identity = "test_rds"

  Fog::AWS[:rds].create_db_instance(@rds_identity,{
    "DBInstanceClass"=>"db.m3.xlarge",
    "Engine"=>"PostgreSQL",
    "AllocatedStorage"=>100,
    "MasterUserPassword"=>"password",
    "MasterUsername"=>"username"
  })

  @rds = Fog::AWS[:rds].servers.get(@rds_identity)

  tests('success') do
    @snapshot_id = "testRdsSnapshot"
    tests("#create_snapshot(#{@rds.identity})").formats(@snapshot_format) do
      Fog::AWS[:rds].create_db_snapshot(@rds.identity,@snapshot_id).body["CreateDBSnapshotResult"]["DBSnapshot"]
    end

    Fog.wait_for { Fog::AWS[:rds].snapshots.get(@snapshot_id) }
    Fog::AWS[:rds].snapshots.get(@snapshot_id).wait_for { ready? }

    tests("#modify_db_snapshot_attribute").formats(@snapshots_format) do
      Fog::AWS[:rds].modify_db_snapshot_attribute(@snapshot_id, {"Add.MemberId"=>["389480430104"]}).body
    end

    tests("#copy_db_snapshot (#{@snapshot_id}, target_snapshot_id)").formats(@snapshot_format)  do
      Fog::AWS[:rds].copy_db_snapshot(@snapshot_id, "target_snapshot_id").body["CopyDBSnapshotResult"]["DBSnapshot"]
    end
  end

  tests('failure') do
    tests("#delete_snapshot('snap-00000000')").raises(Fog::AWS::RDS::NotFound) do
      Fog::AWS[:rds].delete_db_snapshot(@rds.identity)
    end
  end

  @rds.destroy

end
