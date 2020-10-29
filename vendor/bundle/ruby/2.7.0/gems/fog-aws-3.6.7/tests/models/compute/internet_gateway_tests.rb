Shindo.tests("Fog::Compute[:aws] | internet_gateway", ['aws']) do
  model_tests(Fog::Compute[:aws].internet_gateways , {}, true)
end
