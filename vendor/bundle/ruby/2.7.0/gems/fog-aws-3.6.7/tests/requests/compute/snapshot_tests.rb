Shindo.tests('Fog::Compute[:aws] | snapshot requests', ['aws']) do

  @snapshot_format = {
    'description' => Fog::Nullable::String,
    'encrypted'   => Fog::Boolean,
    'ownerId'     => String,
    'progress'    => String,
    'snapshotId'  => String,
    'startTime'   => Time,
    'status'      => String,
    'volumeId'    => String,
    'volumeSize'  => Integer
  }

  @snapshots_format = {
    'requestId'   => String,
    'snapshotSet' => [@snapshot_format.merge('tagSet' => {})]
  }

  @snapshot_copy_result = {
    'requestId'   => String,
    'snapshotId'  => String
  }

  @volume = Fog::Compute[:aws].volumes.create(:availability_zone => 'us-east-1a', :size => 1)

  tests('success') do

    @snapshot_id = nil

    tests("#create_snapshot(#{@volume.identity})").formats(@snapshot_format.merge('progress' => NilClass, 'requestId' => String)) do
      data = Fog::Compute[:aws].create_snapshot(@volume.identity).body
      @snapshot_id = data['snapshotId']
      data
    end

    Fog.wait_for { Fog::Compute[:aws].snapshots.get(@snapshot_id) }
    Fog::Compute[:aws].snapshots.get(@snapshot_id).wait_for { ready? }

    tests("#describe_snapshots").formats(@snapshots_format) do
      Fog::Compute[:aws].describe_snapshots.body
    end

    tests("#describe_snapshots('snapshot-id' => '#{@snapshot_id}')").formats(@snapshots_format) do
      Fog::Compute[:aws].describe_snapshots('snapshot-id' => @snapshot_id).body
    end

    tests("#copy_snapshot (#{@snapshot_id}, 'us-east-1')").formats(@snapshot_copy_result) do
      data = Fog::Compute.new(:provider => :aws, :region => "us-west-1").copy_snapshot(@snapshot_id, "us-east-1").body
      @west_snapshot_id = data['snapshotId']
      data
    end

    tests("#delete_snapshots(#{@snapshot_id})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_snapshot(@snapshot_id).body
    end

    #NOTE: waiting for the copy to complete can sometimes take up to 5 minutes (but sometimes it's nearly instant)
    #for faster tests: comment out the rest of this block
    Fog.wait_for { Fog::Compute.new(:provider => :aws, :region => "us-west-1").snapshots.get(@west_snapshot_id) }

    tests("#delete_snapshots(#{@west_snapshot_id})").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute.new(:provider => :aws, :region => "us-west-1").delete_snapshot(@west_snapshot_id).body
    end

  end
  tests('failure') do

    tests("#delete_snapshot('snap-00000000')").raises(Fog::AWS::Compute::NotFound) do
      Fog::Compute[:aws].delete_snapshot('snap-00000000')
    end

  end

  @volume.destroy

end
