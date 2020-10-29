Shindo.tests("Fog::Compute[:aws] | volumes", ['aws']) do

  collection_tests(Fog::Compute[:aws].volumes, {:availability_zone => 'us-east-1a', :size => 1, :device => '/dev/sdz1'}, true)

end
