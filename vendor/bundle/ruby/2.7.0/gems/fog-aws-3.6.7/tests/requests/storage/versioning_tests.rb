def clear_bucket
  Fog::Storage[:aws].get_bucket_object_versions(@aws_bucket_name).body['Versions'].each do |version|
    object = version[version.keys.first]
    Fog::Storage[:aws].delete_object(@aws_bucket_name, object['Key'], 'versionId' => object['VersionId'])
  end
end

def create_versioned_bucket
  @aws_bucket_name = 'fogbuckettests-' + Fog::Mock.random_hex(16)
  Fog::Storage[:aws].put_bucket(@aws_bucket_name)
  Fog::Storage[:aws].put_bucket_versioning(@aws_bucket_name, 'Enabled')
end

def delete_bucket
  Fog::Storage[:aws].get_bucket_object_versions(@aws_bucket_name).body['Versions'].each do |version|
    object = version[version.keys.first]
    Fog::Storage[:aws].delete_object(@aws_bucket_name, object['Key'], 'versionId' => object['VersionId'])
  end

  Fog::Storage[:aws].delete_bucket(@aws_bucket_name)
end

Shindo.tests('Fog::Storage[:aws] | versioning', ["aws"]) do
  tests('success') do
    tests("#put_bucket_versioning") do
      @aws_bucket_name = 'fogbuckettests-' + Fog::Mock.random_hex(16)
      Fog::Storage[:aws].put_bucket(@aws_bucket_name)

      tests("#put_bucket_versioning('#{@aws_bucket_name}', 'Enabled')").succeeds do
        Fog::Storage[:aws].put_bucket_versioning(@aws_bucket_name, 'Enabled')
      end

      tests("#put_bucket_versioning('#{@aws_bucket_name}', 'Suspended')").succeeds do
        Fog::Storage[:aws].put_bucket_versioning(@aws_bucket_name, 'Suspended')
      end

      delete_bucket
    end

    tests("#get_bucket_versioning('#{@aws_bucket_name}')") do
      @aws_bucket_name = 'fogbuckettests-' + Fog::Mock.random_hex(16)
      Fog::Storage[:aws].put_bucket(@aws_bucket_name)

      tests("#get_bucket_versioning('#{@aws_bucket_name}') without versioning").returns({}) do
        Fog::Storage[:aws].get_bucket_versioning(@aws_bucket_name).body['VersioningConfiguration']
      end

      tests("#get_bucket_versioning('#{@aws_bucket_name}') with versioning enabled").returns('Enabled') do
        Fog::Storage[:aws].put_bucket_versioning(@aws_bucket_name, 'Enabled')
        Fog::Storage[:aws].get_bucket_versioning(@aws_bucket_name).body['VersioningConfiguration']['Status']
      end

      tests("#get_bucket_versioning('#{@aws_bucket_name}') with versioning suspended").returns('Suspended') do
        Fog::Storage[:aws].put_bucket_versioning(@aws_bucket_name, 'Suspended')
        Fog::Storage[:aws].get_bucket_versioning(@aws_bucket_name).body['VersioningConfiguration']['Status']
      end

      delete_bucket
    end

    tests("#get_bucket_object_versions('#{@aws_bucket_name}')") do

      create_versioned_bucket

      before do
        @versions = Fog::Storage[:aws].get_bucket_object_versions(@aws_bucket_name)
      end

      v1 = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'a',    :key => 'file')
      v2 = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'ab',   :key => v1.key)
      v3 = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'abc',  :key => v1.key)
      v4 = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'abcd', :key => v1.key)

      tests("versions").returns([v4.version, v3.version, v2.version, v1.version]) do
        @versions.body['Versions'].map {|v| v['Version']['VersionId']}
      end

      tests("version sizes").returns([4, 3, 2, 1]) do
        @versions.body['Versions'].map {|v| v['Version']['Size']}
      end

      tests("latest version").returns(v4.version) do
        latest = @versions.body['Versions'].find {|v| v['Version']['IsLatest']}
        latest['Version']['VersionId']
      end
    end

    tests("get_object('#{@aws_bucket_name}', 'file')") do
      clear_bucket

      v1 = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'a',  :key => 'file')
      v2 = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'ab', :key => v1.key)

      tests("get_object('#{@aws_bucket_name}', '#{v2.key}') returns the latest version").returns(v2.version) do
        res = Fog::Storage[:aws].get_object(@aws_bucket_name, v2.key)
        res.headers['x-amz-version-id']
      end

      tests("get_object('#{@aws_bucket_name}', '#{v1.key}', 'versionId' => '#{v1.version}') returns the specified version").returns(v1.version) do
        res = Fog::Storage[:aws].get_object(@aws_bucket_name, v1.key, 'versionId' => v1.version)
        res.headers['x-amz-version-id']
      end

      v2.destroy

      tests("get_object('#{@aws_bucket_name}', '#{v2.key}') raises exception if delete marker is latest version").raises(Excon::Errors::NotFound) do
        Fog::Storage[:aws].get_object(@aws_bucket_name, v2.key)
      end
    end

    tests("delete_object('#{@aws_bucket_name}', 'file')") do
      clear_bucket

      file = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'a',  :key => 'file')

      tests("deleting an object just stores a delete marker").returns(true) do
        file.destroy
        versions = Fog::Storage[:aws].get_bucket_object_versions(@aws_bucket_name)
        versions.body['Versions'].first.key?('DeleteMarker')
      end

      tests("there are two versions: the original and the delete marker").returns(2) do
        versions = Fog::Storage[:aws].get_bucket_object_versions(@aws_bucket_name)
        versions.body['Versions'].size
      end

      tests("deleting the delete marker makes the object available again").returns(file.version) do
        versions = Fog::Storage[:aws].get_bucket_object_versions(@aws_bucket_name)
        delete_marker = versions.body['Versions'].find { |v| v.key?('DeleteMarker') }
        Fog::Storage[:aws].delete_object(@aws_bucket_name, file.key, 'versionId' => delete_marker['DeleteMarker']['VersionId'])

        res = Fog::Storage[:aws].get_object(@aws_bucket_name, file.key)
        res.headers['x-amz-version-id']
      end
    end

    tests("deleting_multiple_objects('#{@aws_bucket_name}", 'file') do
      clear_bucket

      bucket = Fog::Storage[:aws].directories.get(@aws_bucket_name)

      file_count = 5
      file_names = []
      files = {}
      file_count.times do |id|
        file_names << "file_#{id}"
        files[file_names.last] = bucket.files.create(:body => 'a',
                                                     :key => file_names.last)
      end

      tests("deleting an object just stores a delete marker").returns(true) do
        Fog::Storage[:aws].delete_multiple_objects(@aws_bucket_name,
                                                   file_names)
        versions = Fog::Storage[:aws].get_bucket_object_versions(
                      @aws_bucket_name)
        all_versions = {}
        versions.body['Versions'].each do |version|
          object = version[version.keys.first]
          next if file_names.index(object['Key']).nil?
          if !all_versions.key?(object['Key'])
            all_versions[object['Key']] = version.key?('DeleteMarker')
          else
            all_versions[object['Key']] |= version.key?('DeleteMarker')
          end
        end
        all_true = true
        all_versions.values.each do |marker|
          all_true = false if !marker
        end
        all_true
      end

      tests("there are two versions: the original and the delete marker").
          returns(file_count*2) do
        versions = Fog::Storage[:aws].get_bucket_object_versions(
                      @aws_bucket_name)
        versions.body['Versions'].size
      end

      tests("deleting the delete marker makes the object available again").
          returns(true) do
        versions = Fog::Storage[:aws].get_bucket_object_versions(
                      @aws_bucket_name)
        delete_markers = []
        file_versions = {}
        versions.body['Versions'].each do |version|
          object = version[version.keys.first]
          next if object['VersionId'] == files[object['Key']].version
          file_versions[object['Key']] = object['VersionId']
        end

        Fog::Storage[:aws].delete_multiple_objects(@aws_bucket_name,
                                                   file_names,
                                                   'versionId' => file_versions)
        all_true = true
        file_names.each do |file|
          res = Fog::Storage[:aws].get_object(@aws_bucket_name, file)
          all_true = false if res.headers['x-amz-version-id'] !=
                              files[file].version
        end
        all_true
      end

    end

    tests("get_bucket('#{@aws_bucket_name}'") do
      clear_bucket

      file = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'a',  :key => 'file')

      tests("includes a non-DeleteMarker object").returns(1) do
        Fog::Storage[:aws].get_bucket(@aws_bucket_name).body['Contents'].size
      end

      file.destroy

      tests("does not include a DeleteMarker object").returns(0) do
        Fog::Storage[:aws].get_bucket(@aws_bucket_name).body['Contents'].size
      end
    end

    delete_bucket
  end

  tests('failure') do
    create_versioned_bucket

    tests("#put_bucket_versioning('#{@aws_bucket_name}', 'bad_value')").raises(Excon::Errors::BadRequest) do
      Fog::Storage[:aws].put_bucket_versioning(@aws_bucket_name, 'bad_value')
    end

    tests("#get_bucket_object_versions('#{@aws_bucket_name}', { 'version-id-marker' => 'foo' })").raises(Excon::Errors::BadRequest) do
      Fog::Storage[:aws].get_bucket_object_versions(@aws_bucket_name, { 'version-id-marker' => 'foo' })
    end

    tests("#put_bucket_versioning('fognonbucket', 'Enabled')").raises(Excon::Errors::NotFound) do
      Fog::Storage[:aws].put_bucket_versioning('fognonbucket', 'Enabled')
    end

    tests("#get_bucket_versioning('fognonbucket')").raises(Excon::Errors::NotFound) do
      Fog::Storage[:aws].get_bucket_versioning('fognonbucket')
    end

    tests("#get_bucket_object_versions('fognonbucket')").raises(Excon::Errors::NotFound) do
      Fog::Storage[:aws].get_bucket_object_versions('fognonbucket')
    end

    file = Fog::Storage[:aws].directories.get(@aws_bucket_name).files.create(:body => 'y', :key => 'x')

    tests("#get_object('#{@aws_bucket_name}', '#{file.key}', 'versionId' => 'bad_version'").raises(Excon::Errors::BadRequest) do
      Fog::Storage[:aws].get_object(@aws_bucket_name, file.key, 'versionId' => '-1')
    end

    tests("#delete_object('#{@aws_bucket_name}', '#{file.key}', 'versionId' => 'bad_version'").raises(Excon::Errors::BadRequest) do
      Fog::Storage[:aws].delete_object(@aws_bucket_name, file.key, 'versionId' => '-1')
    end

  end

  # don't keep the bucket around
  delete_bucket
end
