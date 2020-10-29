Shindo.tests('AWS::RDS | instance requests', ['aws', 'rds']) do

  # random_differentiator
  # Useful when rapidly re-running tests, so we don't have to wait
  # serveral minutes for deleted servers to disappear
  suffix = rand(65536).to_s(16)

  @db_instance_id         = "fog-test-#{suffix}"
  @db_replica_id          = "fog-replica-#{suffix}"
  @db_snapshot_id         = "fog-snapshot-#{suffix}"
  @db_final_snapshot_id   = "fog-final-snapshot-#{suffix}"
  @db_instance_restore_id = "fog-test-#{suffix}"

  tests('success') do

    tests("#create_db_instance").formats(AWS::RDS::Formats::CREATE_DB_INSTANCE) do
      default_params = rds_default_server_params

      # creation of replicas requires a > 0 BackupRetentionPeriod value
      # InvalidDBInstanceState => Automated backups are not enabled for this database instance. To enable automated backups, use ModifyDBInstance to set the backup retention period to a non-zero value. (Fog::AWS::RDS::Error)
      backup_retention_period = 1

      result = Fog::AWS[:rds].create_db_instance(@db_instance_id,
                                                 'AllocatedStorage'      => default_params.fetch(:allocated_storage),
                                                 'DBInstanceClass'       => default_params.fetch(:flavor_id),
                                                 'Engine'                => default_params.fetch(:engine),
                                                 'EngineVersion'         => default_params.fetch(:version),
                                                 'MasterUsername'        => default_params.fetch(:master_username),
                                                 'BackupRetentionPeriod' => backup_retention_period,
                                                 'MasterUserPassword'    => default_params.fetch(:password)).body

      instance = result['CreateDBInstanceResult']['DBInstance']
      returns('creating') { instance['DBInstanceStatus'] }
      result
    end

    tests("#describe_db_instances").formats(AWS::RDS::Formats::DESCRIBE_DB_INSTANCES) do
      Fog::AWS[:rds].describe_db_instances.body
    end

    server = Fog::AWS[:rds].servers.get(@db_instance_id)
    server.wait_for { ready? }

    new_storage = 6
    tests("#modify_db_instance with immediate apply").formats(AWS::RDS::Formats::MODIFY_DB_INSTANCE) do
      body = Fog::AWS[:rds].modify_db_instance(@db_instance_id, true, 'AllocatedStorage' => new_storage).body
      tests 'pending storage' do
        instance = body['ModifyDBInstanceResult']['DBInstance']
        returns(new_storage) { instance['PendingModifiedValues']['AllocatedStorage'] }
      end
      body
    end

    server.wait_for { state == 'modifying' }
    server.wait_for { state == 'available' }

    tests 'new storage' do
      returns(new_storage) { server.allocated_storage }
    end

    tests("reboot db instance") do
      tests("#reboot").formats(AWS::RDS::Formats::REBOOT_DB_INSTANCE) do
        Fog::AWS[:rds].reboot_db_instance(@db_instance_id).body
      end
    end

    server.wait_for { state == 'rebooting' }
    server.wait_for { state == 'available' }

    tests("#create_db_snapshot").formats(AWS::RDS::Formats::CREATE_DB_SNAPSHOT) do
      body = Fog::AWS[:rds].create_db_snapshot(@db_instance_id, @db_snapshot_id).body
      returns('creating') { body['CreateDBSnapshotResult']['DBSnapshot']['Status'] }
      body
    end

    tests("#describe_db_snapshots").formats(AWS::RDS::Formats::DESCRIBE_DB_SNAPSHOTS) do
      Fog::AWS[:rds].describe_db_snapshots.body
    end

    server.wait_for { state == 'available' }

    tests("#create read replica").formats(AWS::RDS::Formats::CREATE_READ_REPLICA) do
      Fog::AWS[:rds].create_db_instance_read_replica(@db_replica_id, @db_instance_id).body
    end

    replica = Fog::AWS[:rds].servers.get(@db_replica_id)
    replica.wait_for { ready? }

    tests("replica source") do
      returns(@db_instance_id) { replica.read_replica_source }
    end
    server.reload

    tests("replica identifiers") do
      returns([@db_replica_id]) { server.read_replica_identifiers }
    end

    tests("#promote read replica").formats(AWS::RDS::Formats::PROMOTE_READ_REPLICA) do
      Fog::AWS[:rds].promote_read_replica(@db_replica_id).body
    end

    tests("#delete_db_instance").formats(AWS::RDS::Formats::DELETE_DB_INSTANCE) do
      #server.wait_for { state == 'available' }
      Fog::AWS[:rds].delete_db_instance(@db_replica_id, nil, true)
      body = Fog::AWS[:rds].delete_db_instance(@db_instance_id, @db_final_snapshot_id).body

      tests "final snapshot" do
        returns('creating') { Fog::AWS[:rds].describe_db_snapshots(:snapshot_id => @db_final_snapshot_id).body['DescribeDBSnapshotsResult']['DBSnapshots'].first['Status'] }
      end
      body
    end

    tests("#restore_db_instance_from_db_snapshot").formats(AWS::RDS::Formats::RESTORE_DB_INSTANCE_FROM_DB_SNAPSHOT) do
      snapshot = Fog::AWS[:rds].snapshots.get(@db_final_snapshot_id)
      snapshot.wait_for { state == 'available' }
      result = Fog::AWS[:rds].restore_db_instance_from_db_snapshot(@db_final_snapshot_id, @db_instance_restore_id).body
      instance = result['RestoreDBInstanceFromDBSnapshotResult']['DBInstance']
      returns('creating') { instance['DBInstanceStatus'] }
      result
    end
    restore_server = Fog::AWS[:rds].servers.get(@db_instance_restore_id)
    restore_server.wait_for { state == 'available' }

    tests("#delete_db_snapshot").formats(AWS::RDS::Formats::DELETE_DB_SNAPSHOT) do
      Fog::AWS[:rds].snapshots.get(@db_snapshot_id).wait_for { ready? }
      Fog::AWS[:rds].delete_db_snapshot(@db_snapshot_id).body
    end

    tests("snapshot.destroy") do
      snapshot = Fog::AWS[:rds].snapshots.get(@db_final_snapshot_id)
      snapshot.wait_for { ready? }
      snapshot.destroy
      returns(nil) { Fog::AWS[:rds].snapshots.get(@db_final_snapshot_id) }
    end

  end

  tests('failure') do
    tests "deleting nonexisting instance" do
      raises(Fog::AWS::RDS::NotFound) { Fog::AWS[:rds].delete_db_instance('doesnexist', 'irrelevant') }
    end
    tests "deleting non existing snapshot" do
      raises(Fog::AWS::RDS::NotFound) { Fog::AWS[:rds].delete_db_snapshot('doesntexist') }
    end
    tests "modifying non existing instance" do
      raises(Fog::AWS::RDS::NotFound) { Fog::AWS[:rds].modify_db_instance 'doesntexit', true, 'AllocatedStorage' => 10 }
    end
  end
end
