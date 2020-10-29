Shindo.tests("Fog::Compute[:aws] | key_pair", ['aws']) do

  model_tests(Fog::Compute[:aws].key_pairs, {:name => 'fogkeyname'}, true)

  after do
    @keypair.destroy
  end

  tests("new keypair") do
    @keypair = Fog::Compute[:aws].key_pairs.create(:name => 'testkey')

    test ("writable?") do
      @keypair.writable? == true
    end
  end

  tests("existing keypair") do
    Fog::Compute[:aws].key_pairs.create(:name => 'testkey')
    @keypair = Fog::Compute[:aws].key_pairs.get('testkey')

    test("writable?") do
      @keypair.writable? == false
    end
  end

end
