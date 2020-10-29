Shindo.tests('AWS::RDS | tagging requests', ['aws', 'rds']) do
  @rds = Fog::AWS[:rds]
  @db_instance_id = "fog-test-#{rand(65536).to_s(16)}"
  Fog::Formatador.display_line "Creating RDS instance #{@db_instance_id}"
  @rds.create_db_instance(@db_instance_id, 'AllocatedStorage' => 5,
        'DBInstanceClass' => 'db.t1.micro', 'Engine' => 'mysql',
        'MasterUsername' => 'foguser', 'MasterUserPassword' => 'fogpassword')
  Fog::Formatador.display_line "Waiting for instance #{@db_instance_id} to be ready"
  @db = @rds.servers.get(@db_instance_id)
  @db.wait_for { ready? }

  tests('success') do

    single_tag  = {'key1' => 'value1'}
    two_tags    = {'key2' => 'value2', 'key3' => 'value3'}

    tests("#add_tags_to_resource with a single tag").
    formats(AWS::RDS::Formats::BASIC) do
      result = @rds.add_tags_to_resource(@db_instance_id, single_tag).body
      returns(single_tag) do
        @rds.list_tags_for_resource(@db_instance_id).
          body['ListTagsForResourceResult']['TagList']
      end
      result
    end

    tests("#add_tags_to_resource with a multiple tags").
    formats(AWS::RDS::Formats::BASIC) do
      result = @rds.add_tags_to_resource(@db_instance_id, two_tags).body
      returns(single_tag.merge(two_tags)) do
        @rds.list_tags_for_resource(@db_instance_id).
          body['ListTagsForResourceResult']['TagList']
      end
      result
    end

    tests("#remove_tags_from_resource").formats(AWS::RDS::Formats::BASIC) do
      result = @rds.remove_tags_from_resource(
                @db_instance_id, single_tag.keys).body
      returns(two_tags) do
        @rds.list_tags_for_resource(@db_instance_id).
          body['ListTagsForResourceResult']['TagList']
      end
      result
    end

    tests("#list_tags_for_resource").
    formats(AWS::RDS::Formats::LIST_TAGS_FOR_RESOURCE) do
      result = @rds.list_tags_for_resource(@db_instance_id).body
      returns(two_tags) do
        result['ListTagsForResourceResult']['TagList']
      end
      result
    end

  end

  tests('failure') do
    tests "tagging a nonexisting instance" do
      raises(Fog::AWS::RDS::NotFound) do
        @rds.add_tags_to_resource('doesnexist', {'key1' => 'value1'})
      end
    end
    tests "listing tags for a nonexisting instance" do
      raises(Fog::AWS::RDS::NotFound) do
        @rds.list_tags_for_resource('doesnexist')
      end
    end
    tests "removing tags for a nonexisting instance" do
      raises(Fog::AWS::RDS::NotFound) do
        @rds.remove_tags_from_resource('doesnexist', ['key1'])
      end
    end
  end

  Fog::Formatador.display_line "Destroying DB instance #{@db_instance_id}"
  @db.destroy
end
