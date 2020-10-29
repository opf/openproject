Shindo.tests("Fog::Compute[:aws] | key_pairs", ['aws']) do

  collection_tests(Fog::Compute[:aws].key_pairs, {:name => 'fogkeyname'}, true)

end
