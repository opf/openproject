Shindo.tests("Fog::CDN[:aws] | invalidations", ['aws', 'cdn']) do
  tests("distributions#create").succeeds do
    @distribution = Fog::CDN[:aws].distributions.create(:s3_origin => {'DNSName' => 'fog_test.s3.amazonaws.com'}, :enabled => true)
  end

  collection_tests(@distribution.invalidations, { :paths => [ '/index.html' ]}, true)

  tests("distribution#destroy - may take 15/20 minutes to complete").succeeds do
    @distribution.wait_for { ready? }
    @distribution.disable
    @distribution.wait_for { ready? }
    @distribution.destroy
  end
end
