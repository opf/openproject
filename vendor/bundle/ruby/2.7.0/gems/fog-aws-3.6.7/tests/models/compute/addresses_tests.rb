Shindo.tests("Fog::Compute[:aws] | addresses", ['aws']) do

  collection_tests(Fog::Compute[:aws].addresses, {}, true)

end
