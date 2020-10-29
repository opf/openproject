Shindo.tests("AWS::RDS | cluster", ["aws", "rds"]) do
  model_tests(Fog::AWS[:rds].clusters, rds_default_cluster_params) do
    @cluster_id = @instance.id
    @instance.wait_for(20*60) { ready? }
    @cluster_with_final_snapshot = Fog::AWS[:rds].clusters.create(rds_default_cluster_params.merge(:id => uniq_id("fog-snapshot-test"), :backup_retention_period => 1))

    tests("#servers") do
      returns([]) { @instance.servers }
    end

    @server = Fog::AWS[:rds].servers.create(rds_default_server_params.reject { |k,v| [:allocated_storage, :master_username, :password, :backup_retention_period].include?(k) }.merge(:engine => "aurora", :cluster_id => @instance.id, :flavor_id => "db.r3.large"))
    @server.wait_for(20*60) { ready? }

    tests("#servers") do
      @instance.reload
      returns([{"DBInstanceIdentifier" => @server.id, "master" => true}]) { @instance.db_cluster_members }
      returns([@server]) { @instance.servers }
    end

    tests("#snapshots") do
      returns([]) { @instance.snapshots }

      snapshot_id = uniq_id("manual-snapshot")
      snapshot = @instance.snapshots.create(:id => snapshot_id)
      returns(snapshot_id) { snapshot.id }
      snapshot.wait_for { ready? }
      returns([snapshot.id]) { @instance.snapshots.map(&:id) }
      snapshot.destroy
    end

    tests("#destroy") do
      snapshot_id = uniq_id("fog-snapshot")

      @instance.servers.map(&:destroy)

      @cluster_with_final_snapshot.wait_for(20*60) { ready? }
      @cluster_with_final_snapshot.destroy(snapshot_id)

      snapshot = Fog::AWS[:rds].cluster_snapshots.get(snapshot_id)
      snapshot.wait_for { ready? }
      returns(snapshot_id) { snapshot.id }
      snapshot.destroy
    end

    after do
      if cluster = Fog::AWS[:rds].clusters.get(@cluster_id)
        unless cluster.state = 'deleting'
          cluster.servers.map(&:destroy)
          cluster.destroy
        end
      end
    end
  end
end
