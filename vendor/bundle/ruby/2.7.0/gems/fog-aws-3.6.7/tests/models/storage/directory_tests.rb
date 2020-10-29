Shindo.tests("Storage[:aws] | directory", ["aws"]) do

  directory_attributes = {
    :key => uniq_id('fogdirectorytests')
  }

  model_tests(Fog::Storage[:aws].directories, directory_attributes, Fog.mocking?) do
    tests("#public_url").returns(nil) do
      @instance.public_url
    end

    tests('#location').returns('us-east-1') do # == Fog::AWS::Storage::DEFAULT_REGION
      @instance.location
    end

    @instance.acl = 'public-read'
    @instance.save

    tests("#public_url").returns(true) do
      if @instance.public_url =~ %r[\Ahttps://fogdirectorytests-[\da-f]+\.s3\.amazonaws\.com/\z]
        true
      else
        @instance.public_url
      end
    end
  end

  directory_attributes = {
    :key => uniq_id('different-region'),
    :location => 'eu-west-1',
  }

  model_tests(Fog::Storage[:aws].directories, directory_attributes, Fog.mocking?) do
    tests("#location").returns('eu-west-1') do
      @instance.location
    end

    tests("#location").returns('eu-west-1') do
      Fog::Storage[:aws].directories.get(@instance.identity).location
    end
  end

  directory_attributes = {
    :key => uniq_id('fogdirectorytests')
  }

  model_tests(Fog::Storage[:aws].directories, directory_attributes, Fog.mocking?) do

    tests("#versioning=") do
      tests("#versioning=(true)").succeeds do
        @instance.versioning = true
      end

      tests("#versioning=(true) sets versioning to 'Enabled'").returns('Enabled') do
        @instance.versioning = true
        @instance.service.get_bucket_versioning(@instance.key).body['VersioningConfiguration']['Status']
      end

      tests("#versioning=(false)").succeeds do
        (@instance.versioning = false).equal? false
      end

      tests("#versioning=(false) sets versioning to 'Suspended'").returns('Suspended') do
        @instance.versioning = false
        @instance.service.get_bucket_versioning(@instance.key).body['VersioningConfiguration']['Status']
      end
    end

  end

  model_tests(Fog::Storage[:aws].directories, directory_attributes, Fog.mocking?) do

    tests("#versioning?") do
      tests("#versioning? false if not enabled").returns(false) do
        @instance.versioning?
      end

      tests("#versioning? true if enabled").returns(true) do
        @instance.service.put_bucket_versioning(@instance.key, 'Enabled')
        @instance.versioning?
      end

      tests("#versioning? false if suspended").returns(false) do
        @instance.service.put_bucket_versioning(@instance.key, 'Suspended')
        @instance.versioning?
      end
    end

  end

end
