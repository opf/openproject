Shindo.tests("Fog::DNS[:aws] | zones", ['aws', 'dns']) do
  params = {:domain => generate_unique_domain }
  collection_tests(Fog::DNS[:aws].zones, params)
end
