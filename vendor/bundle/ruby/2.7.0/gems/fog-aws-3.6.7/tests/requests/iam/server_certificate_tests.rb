Shindo.tests('AWS::IAM | server certificate requests', ['aws']) do
  @key_name = 'fog-test'
  @key_name_chained = 'fog-test-chained'

  @certificate_format = {
    'Arn' => String,
    'Path' => String,
    'ServerCertificateId' => String,
    'ServerCertificateName' => String,
    'UploadDate' => Time
  }
  @upload_format = {
    'Certificate' => @certificate_format,
    'RequestId' => String
  }
  @update_format = {
    'RequestId' => String
  }
  @get_server_certificate_format = {
    'Certificate' => @certificate_format,
    'RequestId' => String
  }
  @list_format = {
    'Certificates' => [@certificate_format]
  }

  tests('#upload_server_certificate') do
    public_key  = AWS::IAM::SERVER_CERT
    private_key = AWS::IAM::SERVER_CERT_PRIVATE_KEY
    private_key_pkcs8 = AWS::IAM::SERVER_CERT_PRIVATE_KEY_PKCS8
    private_key_mismatch = AWS::IAM::SERVER_CERT_PRIVATE_KEY_MISMATCHED

    tests('empty public key').raises(Fog::AWS::IAM::ValidationError) do
      Fog::AWS::IAM.new.upload_server_certificate('', private_key, @key_name)
    end

    tests('empty private key').raises(Fog::AWS::IAM::ValidationError) do
      Fog::AWS::IAM.new.upload_server_certificate(public_key, '', @key_name)
    end

    tests('invalid public key').raises(Fog::AWS::IAM::MalformedCertificate) do
      Fog::AWS::IAM.new.upload_server_certificate('abcde', private_key, @key_name)
    end

    tests('invalid private key').raises(Fog::AWS::IAM::MalformedCertificate) do
      Fog::AWS::IAM.new.upload_server_certificate(public_key, 'abcde', @key_name)
    end

    tests('non-RSA private key').raises(Fog::AWS::IAM::MalformedCertificate) do
      Fog::AWS::IAM.new.upload_server_certificate(public_key, private_key_pkcs8, @key_name)
    end

    tests('mismatched private key').raises(Fog::AWS::IAM::KeyPairMismatch) do
      Fog::AWS::IAM.new.upload_server_certificate(public_key, private_key_mismatch, @key_name)
    end

    tests('format').formats(@upload_format) do
      Fog::AWS::IAM.new.upload_server_certificate(public_key, private_key, @key_name).body
    end

    tests('format with chain').formats(@upload_format) do
      Fog::AWS::IAM.new.upload_server_certificate(public_key, private_key, @key_name_chained, { 'CertificateChain' => public_key }).body
    end

    tests('duplicate name').raises(Fog::AWS::IAM::EntityAlreadyExists) do
      Fog::AWS::IAM.new.upload_server_certificate(public_key, private_key, @key_name)
    end
  end

  tests('#update_server_certificate') do
    public_key  = AWS::IAM::SERVER_CERT
    private_key = AWS::IAM::SERVER_CERT_PRIVATE_KEY
    key_name    = "update-key"

    Fog::AWS::IAM.new.upload_server_certificate(public_key, private_key, key_name)

    tests('duplicate name').raises(Fog::AWS::IAM::EntityAlreadyExists) do
      other_key_name = "other-key-name"
      Fog::AWS::IAM.new.upload_server_certificate(public_key, private_key, other_key_name)

      Fog::AWS::IAM.new.update_server_certificate(key_name, {'NewServerCertificateName' => other_key_name})
    end

    tests('unknown name').raises(Fog::AWS::IAM::NotFound) do
      Fog::AWS::IAM.new.update_server_certificate("unknown-key-name", {'NewServerCertificateName' => "other-keyname"})
    end

    tests('format').formats(@update_format) do
      Fog::AWS::IAM.new.update_server_certificate(key_name).body
    end

    tests('updates name') do
      other_key_name = "successful-update-key-name"
      Fog::AWS::IAM.new.update_server_certificate(key_name, {'NewServerCertificateName' => other_key_name})
      returns(true) { Fog::AWS::IAM.new.get_server_certificate(other_key_name).body['Certificate']['ServerCertificateName'] == other_key_name }
    end
  end

  tests('#get_server_certificate').formats(@get_server_certificate_format) do
    tests('raises NotFound').raises(Fog::AWS::IAM::NotFound) do
      Fog::AWS::IAM.new.get_server_certificate("#{@key_name}fake")
    end
    Fog::AWS::IAM.new.get_server_certificate(@key_name).body
  end

  tests('#list_server_certificates').formats(@list_format) do
    result = Fog::AWS::IAM.new.list_server_certificates.body
    tests('includes key name') do
      returns(true) { result['Certificates'].any?{|c| c['ServerCertificateName'] == @key_name} }
    end
    result
  end

  tests("#list_server_certificates('path-prefix' => '/'").formats(@list_format) do
    result = Fog::AWS::IAM.new.list_server_certificates('PathPrefix' => '/').body
    tests('includes key name') do
      returns(true) { result['Certificates'].any?{|c| c['ServerCertificateName'] == @key_name} }
    end
    result
  end

  tests('#delete_server_certificate').formats(AWS::IAM::Formats::BASIC) do
    tests('raises NotFound').raises(Fog::AWS::IAM::NotFound) do
      Fog::AWS::IAM.new.delete_server_certificate("#{@key_name}fake")
    end
    Fog::AWS::IAM.new.delete_server_certificate(@key_name).body
  end

  Fog::AWS::IAM.new.delete_server_certificate(@key_name_chained)
end
