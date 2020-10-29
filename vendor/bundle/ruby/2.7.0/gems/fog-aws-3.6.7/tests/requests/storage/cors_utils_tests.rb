require 'fog/aws/requests/storage/cors_utils'

Shindo.tests('Fog::AWS::Storage | CORS utils', ["aws"]) do
  tests(".hash_to_cors") do
    tests(".hash_to_cors({}) at xpath //CORSConfiguration").returns("", "has an empty CORSConfiguration") do
      xml = Fog::AWS::Storage.hash_to_cors({})
      Nokogiri::XML(xml).xpath("//CORSConfiguration").first.content.chomp
    end

    tests(".hash_to_cors({}) at xpath //CORSConfiguration/CORSRule").returns(nil, "has no CORSRules") do
      xml = Fog::AWS::Storage.hash_to_cors({})
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule").first
    end

    cors = {
      'CORSConfiguration' => [
        {
          'AllowedOrigin' => ['origin_123', 'origin_456'],
          'AllowedMethod' => ['GET', 'POST'],
          'AllowedHeader' => ['Accept', 'Content-Type'],
          'ID' => 'blah-888',
          'MaxAgeSeconds' => 2500,
          'ExposeHeader' => ['x-some-header', 'x-other-header']
        }
      ]
    }

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/AllowedOrigin").returns("origin_123", "returns the CORSRule AllowedOrigin") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/AllowedOrigin")[0].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/AllowedOrigin").returns("origin_456", "returns the CORSRule AllowedOrigin") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/AllowedOrigin")[1].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/AllowedMethod").returns("GET", "returns the CORSRule AllowedMethod") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/AllowedMethod")[0].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/AllowedMethod").returns("POST", "returns the CORSRule AllowedMethod") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/AllowedMethod")[1].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/AllowedHeader").returns("Accept", "returns the CORSRule AllowedHeader") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/AllowedHeader")[0].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/AllowedHeader").returns("Content-Type", "returns the CORSRule AllowedHeader") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/AllowedHeader")[1].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/ID").returns("blah-888", "returns the CORSRule ID") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/ID")[0].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/MaxAgeSeconds").returns("2500", "returns the CORSRule MaxAgeSeconds") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/MaxAgeSeconds")[0].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/ExposeHeader").returns("x-some-header", "returns the CORSRule ExposeHeader") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/ExposeHeader")[0].content
    end

    tests(".hash_to_cors(#{cors.inspect}) at xpath //CORSConfiguration/CORSRule/ExposeHeader").returns("x-other-header", "returns the CORSRule ExposeHeader") do
      xml = Fog::AWS::Storage.hash_to_cors(cors)
      Nokogiri::XML(xml).xpath("//CORSConfiguration/CORSRule/ExposeHeader")[1].content
    end
  end

  tests(".cors_to_hash") do
    cors_xml = <<-XML
<CORSConfiguration>
  <CORSRule>
    <AllowedOrigin>http://www.example.com</AllowedOrigin>
    <AllowedOrigin>http://www.example2.com</AllowedOrigin>
    <AllowedHeader>Content-Length</AllowedHeader>
    <AllowedHeader>X-Foobar</AllowedHeader>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedMethod>GET</AllowedMethod>
    <MaxAgeSeconds>3000</MaxAgeSeconds>
    <ExposeHeader>x-amz-server-side-encryption</ExposeHeader>
    <ExposeHeader>x-amz-balls</ExposeHeader>
  </CORSRule>
</CORSConfiguration>
XML

    tests(".cors_to_hash(#{cors_xml.inspect})").returns({
      "CORSConfiguration" => [{
        "AllowedOrigin" => ["http://www.example.com", "http://www.example2.com"],
        "AllowedHeader" => ["Content-Length", "X-Foobar"],
        "AllowedMethod" => ["PUT", "GET"],
        "MaxAgeSeconds" => 3000,
        "ExposeHeader" => ["x-amz-server-side-encryption", "x-amz-balls"]
      }]
    }, 'returns hash of CORS XML') do
      Fog::AWS::Storage.cors_to_hash(cors_xml)
    end
  end
end
