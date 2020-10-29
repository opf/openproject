Shindo.tests("Fog::CDN[:aws] | invalidation", ['aws', 'cdn']) do

  tests("distributions#create").succeeds do
    @distribution = Fog::CDN[:aws].distributions.create(:s3_origin => {'DNSName' => 'fog_test.s3.amazonaws.com'}, :enabled => true)
  end

  params = { :paths => [ '/index.html', '/path/to/index.html' ] }

  model_tests(@distribution.invalidations, params, true) do

    tests("#id") do
      returns(true) { @instance.identity != nil }
    end

    tests("#paths") do
      returns([ '/index.html', '/path/to/index.html' ].sort) { @instance.paths.sort }
    end

    tests("#ready? - may take 15 minutes to complete...").succeeds do
      @instance.wait_for { ready? }
    end
  end

  tests("distribution#destroy - may take around 15/20 minutes to complete...").succeeds do
    @distribution.wait_for { ready? }
    @distribution.disable
    @distribution.wait_for { ready? }
    @distribution.destroy
  end

end
