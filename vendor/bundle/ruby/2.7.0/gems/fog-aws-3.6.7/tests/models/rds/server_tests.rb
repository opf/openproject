Shindo.tests("AWS::RDS | server", ['aws', 'rds']) do
  model_tests(Fog::AWS[:rds].servers, rds_default_server_params) do
    # We'll need this later; create it early to avoid waiting
    @instance_with_final_snapshot = Fog::AWS[:rds].servers.create(rds_default_server_params.merge(:id => uniq_id("fog-snapshot-test"), :backup_retention_period => 1))
    @instance_with_encrypted_storage = Fog::AWS[:rds].servers.create(rds_default_server_params.merge(:storage_encrypted => true))

    @instance.wait_for(20*60) { ready? }
    @instance_with_encrypted_storage.wait_for(20*60) { ready? }
    @final_snapshot_id = uniq_id('fog-test-snapshot')

    tests("#storage_encrypted") do
      returns(true) { @instance_with_encrypted_storage.storage_encrypted }
    end

    test('#read_replica_identifiers is []') do
      returns([]) { @instance.read_replica_identifiers }
    end

    tests('#snapshots') do
      snapshot = nil

      tests('#create').succeeds do
        snapshot = @instance.snapshots.create(:id => uniq_id('fog-snapshot-test'))
      end

      snapshot.wait_for { ready?}

      @instance.wait_for { ready? }

      returns(true) { @instance.snapshots.map{ |s| s.id }.include?(snapshot.id) }
      snapshot.destroy
    end

    tests("#modify").succeeds do
      pending if Fog.mocking?

      engine  = rds_default_server_params.fetch(:engine)
      version = rds_default_server_params.fetch(:version).match(/\d+\.\d+/).to_s

      orig_parameter_group = @instance.db_parameter_groups.first['DBParameterGroupName']
      parameter_group = Fog::AWS[:rds].parameter_groups.create(:id => uniq_id, :family => "#{engine}#{version}", :description => 'fog-test')

      orig_security_groups = @instance.db_security_groups.map{|h| h['DBSecurityGroupName']}
      security_group = Fog::AWS[:rds].security_groups.create(:id => uniq_id, :description => 'fog-test')

      modify_options = {
        'DBParameterGroupName' => parameter_group.id,
        'DBSecurityGroups' => orig_security_groups + [security_group.id]
      }

      @instance.modify(true, modify_options)
      @instance.wait_for { ready? }

      returns(parameter_group.id, 'new parameter group') do
        @instance.db_parameter_groups.first['DBParameterGroupName']
      end

      returns(true, "new security group") do
        @instance.db_security_groups.any?{|hash| hash['DBSecurityGroupName'] == security_group.id}
      end

      @instance.reboot
      @instance.wait_for { state == 'rebooting' }
      @instance.wait_for { ready? }

      # Restore back to original state using symbols
      restore_options = {
       :parameter_group_name => orig_parameter_group,
       :security_group_names => orig_security_groups
      }
      @instance.modify(true, restore_options)

      @instance.reboot
      @instance.wait_for { state == 'rebooting' }
      @instance.wait_for do
        ready? &&
          db_security_groups.all? {|hash| hash['Status'] == 'active'} &&
          db_parameter_groups.all? {|hash| hash['ParameterApplyStatus'] == 'in-sync' }
      end

      parameter_group.destroy
      security_group.destroy
    end

    tests("#reboot").succeeds do
      @instance.reboot
    end
    @instance.wait_for { state == 'rebooting' }
    @instance.wait_for { ready? }

    replica = nil

    tests('#create_read_replica').succeeds do
      replica = @instance_with_final_snapshot.create_read_replica(uniq_id('fog-replica'))
      @instance_with_final_snapshot.reload
      returns([replica.id]) { @instance_with_final_snapshot.read_replica_identifiers }
      returns(@instance_with_final_snapshot.id) { replica.read_replica_source }

      replica.wait_for { ready? }

      # FinalDBSnapshotIdentifier can not be specified when deleting a replica instance
      raises(Fog::AWS::RDS::Error) { replica.destroy("foobar") }
    end

    tests('#promote_read_replica').succeeds do
      replica.promote.wait_for { state != "modifying" }

      replica.read_replica_source == nil
    end

    tests('#promote_read_replica', 'master').raises(Fog::AWS::RDS::Error) {
      @instance_with_final_snapshot.promote
    }

    replica && replica.destroy

    test("Destroying with a final snapshot") do

      @instance_with_final_snapshot.wait_for { ready? }
      @instance_with_final_snapshot.destroy(@final_snapshot_id)
      returns(true, "Final snapshot created") do
        @final_snapshot = Fog::AWS[:rds].snapshots.get(@final_snapshot_id)
        !@final_snapshot.nil?
      end

      @final_snapshot.wait_for { ready? }
      @final_snapshot.destroy
    end

  end
end
