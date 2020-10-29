Shindo.tests("Fog::Compute[:aws] | vpcs", ['aws']) do

  collection_tests(Fog::Compute[:aws].vpcs, {:cidr_block => '10.0.10.0/28'}, true)

  tests('tags') do
    test_tags = {'foo' => 'bar'}
    @vpc = Fog::Compute[:aws].vpcs.create(:cidr_block => '1.2.3.4/24', :tags => test_tags)

    tests('@vpc.tags').returns(test_tags) do
      @vpc.reload.tags
    end

    unless Fog.mocking?
      Fog::Compute[:aws].tags.all('resource-id' => @vpc.id).each {|tag| tag.destroy}
    end

    @vpc.destroy
  end
end
