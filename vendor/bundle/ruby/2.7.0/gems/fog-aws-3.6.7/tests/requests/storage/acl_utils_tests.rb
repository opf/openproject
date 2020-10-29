require 'fog/aws/requests/storage/acl_utils'

Shindo.tests('Fog::AWS::Storage | ACL utils', ["aws"]) do
  tests(".hash_to_acl") do
    tests(".hash_to_acl({}) at xpath //AccessControlPolicy").returns("", "has an empty AccessControlPolicy") do
      xml = Fog::AWS::Storage.hash_to_acl({})
      Nokogiri::XML(xml).xpath("//AccessControlPolicy").first.content.chomp
    end

    tests(".hash_to_acl({}) at xpath //AccessControlPolicy/Owner").returns(nil, "does not have an Owner element") do
      xml = Fog::AWS::Storage.hash_to_acl({})
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/Owner").first
    end

    tests(".hash_to_acl('Owner' => {}) at xpath //AccessControlPolicy/Owner").returns(nil, "does not have an Owner element") do
      xml = Fog::AWS::Storage.hash_to_acl('Owner' => {})
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/Owner").first
    end

    tests(".hash_to_acl('Owner' => {'ID' => 'abcdef0123456789'}) at xpath //AccessControlPolicy/Owner/ID").returns("abcdef0123456789", "returns the Owner ID") do
      xml = Fog::AWS::Storage.hash_to_acl('Owner' => {'ID' => 'abcdef0123456789'})
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/Owner/ID").first.content
    end

    tests(".hash_to_acl('Owner' => {'DisplayName' => 'bob'}) at xpath //AccessControlPolicy/Owner/ID").returns(nil, "does not have an Owner ID element") do
      xml = Fog::AWS::Storage.hash_to_acl('Owner' => {'DisplayName' => 'bob'})
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/Owner/ID").first
    end

    tests(".hash_to_acl('Owner' => {'DisplayName' => 'bob'}) at xpath //AccessControlPolicy/Owner/DisplayName").returns("bob", "returns the Owner DisplayName") do
      xml = Fog::AWS::Storage.hash_to_acl('Owner' => {'DisplayName' => 'bob'})
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/Owner/DisplayName").first.content
    end

    tests(".hash_to_acl('Owner' => {'ID' => 'abcdef0123456789'}) at xpath //AccessControlPolicy/Owner/DisplayName").returns(nil, "does not have an Owner DisplayName element") do
      xml = Fog::AWS::Storage.hash_to_acl('Owner' => {'ID' => 'abcdef0123456789'})
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/Owner/DisplayName").first
    end

    tests(".hash_to_acl({}) at xpath //AccessControlPolicy/AccessControlList").returns(nil, "has no AccessControlList") do
      xml = Fog::AWS::Storage.hash_to_acl({})
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlPolicy").first
    end

    acl = {
      'AccessControlList' => [
        {
          'Grantee' => {
            'ID' => 'abcdef0123456789',
            'DisplayName' => 'bob'
          },
          'Permission' => 'READ'
        }
      ]
    }

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee").returns("CanonicalUser", "has an xsi:type of CanonicalUser") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee").first.attributes["type"].value
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee/ID").returns("abcdef0123456789", "returns the Grantee ID") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee/ID").first.content
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee/DisplayName").returns("bob", "returns the Grantee DisplayName") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee/DisplayName").first.content
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Permission").returns("READ", "returns the Grantee Permission") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Permission").first.content
    end

    acl = {
      'AccessControlList' => [
        {
          'Grantee' => {
            'EmailAddress' => 'user@example.com'
          },
          'Permission' => 'FULL_CONTROL'
        }
      ]
    }

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee").returns("AmazonCustomerByEmail", "has an xsi:type of AmazonCustomerByEmail") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee").first.attributes["type"].value
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee/EmailAddress").returns("user@example.com", "returns the Grantee EmailAddress") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee/EmailAddress").first.content
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Permission").returns("FULL_CONTROL", "returns the Grantee Permission") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Permission").first.content
    end

    acl = {
      'AccessControlList' => [
        {
          'Grantee' => {
            'URI' => 'http://acs.amazonaws.com/groups/global/AllUsers'
          },
          'Permission' => 'WRITE'
        }
      ]
    }

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee").returns("Group", "has an xsi:type of Group") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee").first.attributes["type"].value
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee/URI").returns("http://acs.amazonaws.com/groups/global/AllUsers", "returns the Grantee URI") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee/URI").first.content
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Permission").returns("WRITE", "returns the Grantee Permission") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Permission").first.content
    end

    acl = {
      'AccessControlList' => [
        {
          'Grantee' => {
            'ID' => 'abcdef0123456789',
            'DisplayName' => 'bob'
          },
          'Permission' => 'READ'
        },
        {
          'Grantee' => {
            'EmailAddress' => 'user@example.com'
          },
          'Permission' => 'FULL_CONTROL'
        },
        {
          'Grantee' => {
            'URI' => 'http://acs.amazonaws.com/groups/global/AllUsers'
          },
          'Permission' => 'WRITE'
        }
      ]
    }

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant").returns(3, "has three elements") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant").size
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee/ID").returns("abcdef0123456789", "returns the first Grant's Grantee ID") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee/ID").first.content
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee/EmailAddress").returns("user@example.com", "returns the second Grant's Grantee EmailAddress") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee/EmailAddress").first.content
    end

    tests(".hash_to_acl(#{acl.inspect}) at xpath //AccessControlPolicy/AccessControlList/Grant/Grantee/URI").returns("http://acs.amazonaws.com/groups/global/AllUsers", "returns the third Grant's Grantee URI") do
      xml = Fog::AWS::Storage.hash_to_acl(acl)
      Nokogiri::XML(xml).xpath("//AccessControlPolicy/AccessControlList/Grant/Grantee/URI").first.content
    end
  end

  tests(".acl_to_hash") do
    acl_xml = <<-XML
<AccessControlPolicy>
  <Owner>
    <ID>2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0</ID>
    <DisplayName>me</DisplayName>
  </Owner>
  <AccessControlList>
    <Grant>
      <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
        <ID>2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0</ID>
        <DisplayName>me</DisplayName>
      </Grantee>
      <Permission>FULL_CONTROL</Permission>
    </Grant>
  </AccessControlList>
</AccessControlPolicy>
XML

    tests(".acl_to_hash(#{acl_xml.inspect})").returns({
      "Owner" => {
        "DisplayName" => "me",
        "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"
      },
      "AccessControlList" => [{
        "Grantee" => {
          "DisplayName" => "me",
          "ID" => "2744ccd10c7533bd736ad890f9dd5cab2adb27b07d500b9493f29cdc420cb2e0"
        },
        "Permission" => "FULL_CONTROL"
      }]
    }, 'returns hash of ACL XML') do
      Fog::AWS::Storage.acl_to_hash(acl_xml)
    end
  end
end
