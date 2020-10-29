Shindo.tests("Fog::Compute[:aws] | snapshot", ['aws']) do

  @volume = Fog::Compute[:aws].volumes.create(:availability_zone => 'us-east-1a', :size => 1)
  @volume.wait_for { ready? }

  model_tests(Fog::Compute[:aws].snapshots, {:volume_id => @volume.identity}, true)

  @volume.destroy

end
