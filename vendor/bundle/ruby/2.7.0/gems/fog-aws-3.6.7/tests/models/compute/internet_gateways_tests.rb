Shindo.tests("Fog::Compute[:aws] | internet_gateways", ['aws']) do
  collection_tests(Fog::Compute[:aws].internet_gateways, {}, true)
end
