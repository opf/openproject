Shindo.tests("AWS::RDS | servers", ['aws', 'rds']) do

  collection_tests(Fog::AWS[:rds].servers, rds_default_server_params) do
    @instance.wait_for { ready? }
  end

  tests("#restore").succeeds do
    instance = Fog::AWS[:rds].servers.create(rds_default_server_params.merge(:id => uniq_id("fog-snapshot-test")))

    snapshot_id = uniq_id('fog-snapshot-test')
    @snapshot = instance.snapshots.create(:id => snapshot_id )
    instance.destroy

    db_name = uniq_id('fog-db-name')
    @restore_instance = Fog::AWS[:rds].servers.restore('master_username' => instance.master_username, 'flavor_id' => 'db.m3.medium', 'source_snapshot_id' => snapshot_id, 'id' => uniq_id('restored-instance'))
  end

  if Fog.mocking? && @restore_instance.respond_to?(:ready?)
    @restore_instance.wait_for { ready? }
  end

  @snapshot.destroy
  @restore_instance.destroy
end
