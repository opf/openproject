Shindo.tests("Fog::DNS[:aws] | zone", ['aws', 'dns']) do
  params = {:domain => generate_unique_domain }
  model_tests(Fog::DNS[:aws].zones, params)
end
