Shindo.tests("Fog::DNS[:aws] | records", ['aws', 'dns']) do

  tests("zones#create").succeeds do
    @zone = Fog::DNS[:aws].zones.create(:domain => generate_unique_domain)
  end

  param_groups = [
    # A record
    { :name => @zone.domain, :type => 'A', :ttl => 3600, :value => ['1.2.3.4'] },
    # CNAME record
    { :name => "www.#{@zone.domain}", :type => "CNAME", :ttl => 300, :value => @zone.domain}
  ]

  param_groups.each do |params|
    collection_tests(@zone.records, params)
  end

  records = []

  100.times do |i|
    records << @zone.records.create(:name => "#{i}.#{@zone.domain}", :type => "A", :ttl => 3600, :value => ['1.2.3.4'])
  end

  records << @zone.records.create(:name => "*.#{@zone.domain}", :type => "A", :ttl => 3600, :value => ['1.2.3.4'])

  tests("#all!").returns(101) do
    @zone.records.all!.size
  end

  tests("#all wildcard parsing").returns(true) do
    @zone.records.map(&:name).include?("*.#{@zone.domain}")
  end

  records.each do |record|
    record.destroy
  end

  tests("zones#destroy").succeeds do
    @zone.destroy
  end
end
