Shindo.tests('Fog::DNS[:aws] | change_resource_record_sets', ['aws', 'dns']) do
  tests('success') do
    test('#elb_hosted_zone_mapping from DNS name') do
      zone_id = Fog::AWS::DNS.hosted_zone_for_alias_target('arbitrary-sub-domain.eu-west-1.elb.amazonaws.com')
      zone_id == Fog::AWS::DNS.elb_hosted_zone_mapping['eu-west-1']
    end
  end

  tests("#change_resource_record_sets_data formats geolocation properly") do
    change_batch = [{
        :action=>"CREATE",
        :name=>"ark.m.example.net.",
        :resource_records=>["1.1.1.1"],
        :ttl=>"300",
        :type=>"A",
        :set_identifier=>"ark",
        :geo_location=>{"CountryCode"=>"US", "SubdivisionCode"=>"AR"},
        }]

    version = '2013-04-01'
    result = Fog::AWS::DNS.change_resource_record_sets_data('zone_id123', change_batch, version)
    doc = Nokogiri::XML(result)

    returns("https://route53.amazonaws.com/doc/#{version}/") { doc.namespaces['xmlns'] }
    returns(%w[US AR]) {
      [
        doc.css("GeoLocation CountryCode").text,
        doc.css("GeoLocation SubdivisionCode").text
      ]
    }

    result
  end
end
