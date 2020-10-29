Shindo.tests("Fog::Compute[:aws] | dhcp_options", ['aws']) do
  model_tests(Fog::Compute[:aws].dhcp_options, {'dhcp_configuration_set' => {'domain-name' => 'example.com', 'domain-name-servers' => '10.10.10.10'}}, true)
end
