Shindo.tests("Storage[:aws] | version", ["aws"]) do

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

    @version_instance = @instance.versions.first
    @directory.service.put_object(@directory.key, @instance.key, 'second version content')

    tests("#file") do
      tests("#file should return the object associated with the version").returns(@version_instance.version) do
        @version_instance.file.version
      end
    end

    tests("#delete_marker") do
      tests("#delete_marker should be false if the version isn't a DeleteMarker'").returns(false) do
        @version_instance.delete_marker
      end

      tests("#delete_marker should be true if the version is a DeleteMarker'").returns(true) do
        @instance.destroy

        @instance.versions.all.first.delete_marker
      end
    end

    tests("#destroy") do
      tests("#destroy removes the specific version").returns(false) do
        @version_instance.destroy

        @instance.versions.all.map(&:version).include?(@version_instance.version)
      end
    end

  end

  @directory.versions.each(&:destroy)
  @directory.destroy

end
