Shindo.tests('Fog::Compute[:aws] | key pair requests', ['aws']) do

  tests('success') do

    @keypair_format = {
      'keyFingerprint'  => String,
      'keyName'         => String,
      'requestId'       => String
    }

    @keypairs_format = {
      'keySet' => [{
        'keyFingerprint' => String,
        'keyName' => String
      }],
      'requestId' => String
    }

    @key_pair_name = 'fog_create_key_pair'
    @public_key_material = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1SL+kgze8tvSFW6Tyj3RyZc9iFVQDiCKzjgwn2tS7hyWxaiDhjfY2mBYSZwFdKN+ZdsXDJL4CPutUg4DKoQneVgIC1zuXrlpPbaT0Btu2aFd4qNfJ85PBrOtw2GrWZ1kcIgzZ1mMbQt6i1vhsySD2FEj+5kGHouNxQpI5dFR5K+nGgcTLFGnzb/MPRBk136GVnuuYfJ2I4va/chstThoP8UwnoapRHcBpwTIfbmmL91BsRVqjXZEUT73nxpxFeXXidYwhHio+5dXwE0aM/783B/3cPG6FVoxrBvjoNpQpAcEyjtRh9lpwHZtSEW47WNzpIW3PhbQ8j4MryznqF1Rhw=='

    tests("#create_key_pair('#{@key_pair_name}')").formats(@keypair_format.merge({'keyMaterial' => String})) do
      body = Fog::Compute[:aws].create_key_pair(@key_pair_name).body
      tests("key material").returns(OpenSSL::PKey::RSA, "is a valid private RSA key") do
        OpenSSL::PKey::RSA.new(body['keyMaterial']).class
      end
      body
    end

    tests('#describe_key_pairs').formats(@keypairs_format) do
      Fog::Compute[:aws].describe_key_pairs.body
    end

    tests("#describe_key_pairs('key-name' => '#{@key_pair_name}')").formats(@keypairs_format) do
      Fog::Compute[:aws].describe_key_pairs('key-name' => @key_pair_name).body
    end

    tests("#delete_key_pair('#{@key_pair_name}')").formats(AWS::Compute::Formats::BASIC) do
      Fog::Compute[:aws].delete_key_pair(@key_pair_name).body
    end

    tests("#import_key_pair('fog_import_key_pair', '#{@public_key_material}')").formats(@keypair_format) do
      Fog::Compute[:aws].import_key_pair('fog_import_key_pair', @public_key_material).body
    end

    tests("#delete_key_pair('fog_import_key_pair)").succeeds do
      Fog::Compute[:aws].delete_key_pair('fog_import_key_pair')
    end

    tests("#delete_key_pair('not_a_key_name')").succeeds do
      Fog::Compute[:aws].delete_key_pair('not_a_key_name')
    end

  end
  tests('failure') do

    @key_pair = Fog::Compute[:aws].key_pairs.create(:name => 'fog_key_pair')

    tests("duplicate #create_key_pair('#{@key_pair.name}')").raises(Fog::AWS::Compute::Error) do
      Fog::Compute[:aws].create_key_pair(@key_pair.name)
    end

    @key_pair.destroy

  end

end
