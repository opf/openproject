Shindo.tests("Storage[:aws] | files", ["aws"]) do

  file_attributes = {
      :key => 'fog_file_tests',
      :body => lorem_file,
      :public => true
  }

  directory_attributes = {
      :key => uniq_id('fogfilestests')
  }

  @directory = Fog::Storage[:aws].directories.create(directory_attributes)
  @directory.versioning = true

  model_tests(@directory.files, file_attributes, Fog.mocking?) do

    v1 = @instance.version
    v2 = @directory.service.put_object(@directory.key, @instance.key, 'version 2 content').headers['x-amz-version-id']
    v3 = @directory.service.delete_object(@directory.key, @instance.key).headers['x-amz-version-id']
    v4 = @directory.service.put_object(@directory.key, @instance.key, 'version 3 content').headers['x-amz-version-id']

    tests("#get") do
      tests("#get without version fetches the latest version").returns(v4) do
        @directory.files.get(@instance.key).version
      end

      tests("#get with version fetches that exact version").returns(v2) do
        @directory.files.get(@instance.key, 'versionId' => v2).version
      end

      tests("#get with a deleted version returns nil").returns(nil) do
        pending # getting 405 Method Not Allowed
        @directory.files.get(@instance.key, 'versionId' => v3)
      end
    end

    tests("#head") do
      tests("#head without version fetches the latest version").returns(v4) do
        @directory.files.head(@instance.key).version
      end

      tests("#head with version fetches that exact version").returns(v2) do
        @directory.files.head(@instance.key, 'versionId' => v2).version
      end

      tests("#head with a deleted version returns nil").returns(nil) do
        pending # getting 405 Method Not Allowed
        @directory.files.head(@instance.key, 'versionId' => v3)
      end
    end

  end

  @directory.versions.each(&:destroy)
  @directory.destroy

end
