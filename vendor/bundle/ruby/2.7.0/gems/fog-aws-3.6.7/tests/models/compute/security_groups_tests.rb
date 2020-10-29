Shindo.tests("Fog::Compute[:aws] | security_groups", ['aws']) do

  collection_tests(Fog::Compute[:aws].security_groups, {:description => 'foggroupdescription', :name => 'foggroupname'}, true)

end
