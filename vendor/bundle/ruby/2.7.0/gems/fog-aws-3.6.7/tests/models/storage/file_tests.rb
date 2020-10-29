Shindo.tests("Storage[:aws] | file", ["aws"]) do

  require 'tempfile'

  file_attributes = {
    :key => 'fog_file_tests',
    :body => lorem_file,
    :public => true
  }

  directory_attributes = {
    :key => uniq_id("fogfilestests")
  }

  @directory = Fog::Storage[:aws].directories.create(directory_attributes)

  model_tests(@directory.files, file_attributes, Fog.mocking?) do

    tests("#version") do
      tests("#version should be null if versioning isn't enabled").returns(nil) do
        @instance.version
      end
    end

  end

  @directory.versioning = true

  model_tests(@directory.files, file_attributes, Fog.mocking?) do

    tests("#version") do
      tests("#version should not be null if versioning is enabled").returns(false) do
        @instance.version == nil
      end
    end

    @directory.files.create(:key => @instance.key)
    @instance.destroy

    tests("#versions") do
      tests('#versions.size includes versions (including DeleteMarkers) for all keys').returns(3) do
        @instance.versions.size
      end

      tests('#versions are all for the correct key').returns(true) do
        @instance.versions.all? { |v| v.key == @instance.key }
      end
    end

    tests("#destroy") do
      tests("#destroy a specific version should delete the version, not create a DeleteMarker").returns(2) do
        @instance.destroy('versionId' => @instance.version)
        @instance.versions.all.size
      end
    end

    tests("multipart upload") do
      pending if Fog.mocking?

      # A 6MB file
      @large_file = Tempfile.new("fog-test-aws-s3-multipart")
      6.times { @large_file.write("x" * (1024**2)) }
      @large_file.rewind

      tests("#save(:multipart_chunk_size => 5242880)").succeeds do
        @directory.files.create(:key => 'multipart-upload', :body => @large_file, :multipart_chunk_size => 5242880)
      end

      @large_file.close

    end

    tests("multipart upload with empty file") do
      pending if Fog.mocking?

      @empty_file = Tempfile.new("fog-test-aws-s3-multipart-empty")
     
      tests("#save(:multipart_chunk_size => 5242880)").succeeds do
        @directory.files.create(:key => 'empty-multipart-upload', :body => @empty_file, :multipart_chunk_size => 5242880)
      end

      @empty_file.close
    end

    tests("multipart upload with customer encryption").returns(true) do
      pending if Fog.mocking?

      encryption_key = OpenSSL::Cipher.new("AES-256-ECB").random_key

      # A 6MB file
      @large_file = Tempfile.new("fog-test-aws-s3-multipart")
      6.times { @large_file.write("x" * (1024**2)) }
      @large_file.rewind

      tests("#save(:multipart_chunk_size => 5242880)").succeeds do
        @directory.files.create(
          :key => 'multipart-encrypted-upload',
          :body => @large_file,
          :multipart_chunk_size => 5242880,
          :encryption => "AES256",
          :encryption_key => encryption_key
        )
      end

      @large_file.close

      @directory.files.get('multipart-encrypted-upload',
        'x-amz-server-side-encryption-customer-algorithm' => 'AES256',
        'x-amz-server-side-encryption-customer-key' => Base64.encode64(encryption_key).chomp!,
        'x-amz-server-side-encryption-customer-key-MD5' => Base64.encode64(OpenSSL::Digest::MD5.digest(encryption_key.to_s)).chomp!
      ).body == "x" * 6*1024**2
    end

    acl = Fog::Storage[:aws].get_object_acl(@directory.key, @instance.key).body["AccessControlList"]

    tests("#acl").returns(acl) do
      @instance.acl
    end

    tests("#public?").returns(acl.any? {|grant| grant['Grantee']['URI'] == 'http://acs.amazonaws.com/groups/global/AllUsers' && grant['Permission'] == 'READ'}) do
      @instance.public?
    end

  end

  @directory.versions.each(&:destroy)
  @directory.destroy

end
