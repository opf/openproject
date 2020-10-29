Shindo.tests("Fog::Compute[:aws] | network_acls", ['aws']) do
  @vpc = Fog::Compute[:aws].vpcs.create('cidr_block' => '10.0.10.0/24')

  collection_tests(Fog::Compute[:aws].network_acls, { :vpc_id => @vpc.id }, true)

  tests('tags') do
    test_tags = {'foo' => 'bar'}
    @acl = Fog::Compute[:aws].network_acls.create(:vpc_id => @vpc.id, :tags => test_tags)

    tests('@acl.tags').returns(test_tags) do
      @acl.reload.tags
    end

    unless Fog.mocking?
      Fog::Compute[:aws].tags.all('resource-id' => @acl.identity).each {|tag| tag.destroy}
    end
  end

  @vpc.destroy
end
