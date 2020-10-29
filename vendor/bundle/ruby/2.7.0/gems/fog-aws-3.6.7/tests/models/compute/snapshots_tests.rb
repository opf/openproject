Shindo.tests("Fog::Compute[:aws] | snapshots", ['aws']) do

  @volume = Fog::Compute[:aws].volumes.create(:availability_zone => 'us-east-1a', :size => 1)
  @volume.wait_for { ready? }

  collection_tests(Fog::Compute[:aws].snapshots, {:volume_id => @volume.identity}, true)

  @volume.destroy

end
