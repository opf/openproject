include AWS::Kinesis

Shindo.tests('AWS::Kinesis | stream requests', ['aws', 'kinesis']) do
  Fog::AWS[:kinesis].reset_data if Fog.mocking?

  @stream_id = 'fog-test-stream'

  delete_if_exists(@stream_id) # ensure we start from a clean slate

  tests("#create_stream").returns("") do
    Fog::AWS[:kinesis].create_stream("StreamName" => @stream_id).body.tap do
      wait_for_status(@stream_id, "ACTIVE")
    end
  end

  tests("#list_streams").formats(Formats::LIST_STREAMS_FORMAT, false) do
    Fog::AWS[:kinesis].list_streams.body.tap do
      returns(true) {
        Fog::AWS[:kinesis].list_streams.body["StreamNames"].include?(@stream_id)
      }
    end
  end

  tests("#describe_stream") do
    tests("success").formats(AWS::Kinesis::Formats::DESCRIBE_STREAM_FORMAT) do
      Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id).body
    end

    tests("ResourceNotFound").raises(Fog::AWS::Kinesis::ResourceNotFound) do
      Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id + "-foo").body
    end
  end

  tests("#put_records") do
    records = [
      {
        "Data" => Base64.encode64("foo").chomp!,
        "PartitionKey" => "1"
      },
      {
        "Data" => Base64.encode64("bar").chomp!,
        "PartitionKey" => "1"
      }
    ]

    tests("success").formats(AWS::Kinesis::Formats::PUT_RECORDS_FORMAT, false) do
      Fog::AWS[:kinesis].put_records("StreamName" => @stream_id, "Records" => records).body
    end

    tests("ResourceNotFound").raises(Fog::AWS::Kinesis::ResourceNotFound) do
      Fog::AWS[:kinesis].put_records("StreamName" => @stream_id + "-foo", "Records" => records).body
    end

  end

  tests("#put_record").formats(AWS::Kinesis::Formats::PUT_RECORD_FORMAT) do
    Fog::AWS[:kinesis].put_record("StreamName" => @stream_id, "Data" => Base64.encode64("baz").chomp!, "PartitionKey" => "1").body
  end

  tests("#get_shard_iterator").formats(AWS::Kinesis::Formats::GET_SHARD_ITERATOR_FORMAT) do
    first_shard_id = Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id).body["StreamDescription"]["Shards"].first["ShardId"]
    Fog::AWS[:kinesis].get_shard_iterator("StreamName" => @stream_id, "ShardId" => first_shard_id, "ShardIteratorType" => "TRIM_HORIZON").body
  end

  tests("#get_records").formats(AWS::Kinesis::Formats::GET_RECORDS_FORMAT) do
    first_shard_id = Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id).body["StreamDescription"]["Shards"].first["ShardId"]
    shard_iterator = Fog::AWS[:kinesis].get_shard_iterator("StreamName" => @stream_id, "ShardId" => first_shard_id, "ShardIteratorType" => "TRIM_HORIZON").body["ShardIterator"]
    Fog::AWS[:kinesis].get_records("ShardIterator" => shard_iterator, "Limit" => 1).body
  end

  tests("#get_records").returns(["foo", "bar"]) do
    first_shard_id = Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id).body["StreamDescription"]["Shards"].first["ShardId"]
    shard_iterator = Fog::AWS[:kinesis].get_shard_iterator("StreamName" => @stream_id, "ShardId" => first_shard_id, "ShardIteratorType" => "TRIM_HORIZON").body["ShardIterator"]

    data = []
    2.times do
      response = Fog::AWS[:kinesis].get_records("ShardIterator" => shard_iterator, "Limit" => 1).body
      response["Records"].each do |record|
        data << Base64.decode64(record["Data"])
      end
      shard_iterator = response["NextShardIterator"]
    end
    data
  end

  tests("#split_shard").returns("") do
    shard = Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id).body["StreamDescription"]["Shards"].first
    shard_id = shard["ShardId"]
    ending_hash_key = shard["HashKeyRange"]["EndingHashKey"]
    new_starting_hash_key = (ending_hash_key.to_i / 2).to_s

    result = Fog::AWS[:kinesis].split_shard("StreamName" => @stream_id, "ShardToSplit" => shard_id, "NewStartingHashKey" => new_starting_hash_key).body

    wait_for_status(@stream_id, "ACTIVE")
    shards = Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id).body["StreamDescription"]["Shards"]
    parent_shard = shards.detect{ |shard| shard["ShardId"] == shard_id }
    child_shards = shards.select{ |shard| shard["ParentShardId"] == shard_id }.sort_by{ |shard| shard["ShardId"] }

    returns(3) { shards.size }
    returns(2) { child_shards.size }
    # parent is closed
    returns(false) { parent_shard["SequenceNumberRange"]["EndingSequenceNumber"].nil? }

    # ensure new ranges are what we expect (mostly for testing the mock)
    returns([
              {
                "StartingHashKey" => "0",
                "EndingHashKey" => (new_starting_hash_key.to_i - 1).to_s
              },
              {
                "StartingHashKey" => new_starting_hash_key,
                "EndingHashKey" => ending_hash_key
              }
            ]) { child_shards.map{ |shard| shard["HashKeyRange"] } }

    result
  end

  tests("#merge_shards").returns("") do
    shards = Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id).body["StreamDescription"]["Shards"]
    child_shard_ids = shards.reject{ |shard| shard["SequenceNumberRange"].has_key?("EndingSequenceNumber") }.map{ |shard| shard["ShardId"] }.sort
    result = Fog::AWS[:kinesis].merge_shards("StreamName" => @stream_id, "ShardToMerge" => child_shard_ids[0], "AdjacentShardToMerge" => child_shard_ids[1]).body

    wait_for_status(@stream_id, "ACTIVE")
    shards = Fog::AWS[:kinesis].describe_stream("StreamName" => @stream_id).body["StreamDescription"]["Shards"]
    parent_shards = shards.select{ |shard| child_shard_ids.include?(shard["ShardId"]) }
    child_shard = shards.detect{ |shard|
      shard["ParentShardId"] == child_shard_ids[0] &&
      shard["AdjacentParentShardId"] == child_shard_ids[1]
    }

    returns(2) { parent_shards.size }
    returns(false) { child_shard.nil? }
    returns({
              "EndingHashKey" => "340282366920938463463374607431768211455",
              "StartingHashKey" => "0"
            }) {
      child_shard["HashKeyRange"]
    }

    result
  end

  tests("#add_tags_to_stream").returns("") do
    Fog::AWS[:kinesis].add_tags_to_stream("StreamName" => @stream_id, "Tags" => {"a" => "1", "b" => "2"}).body
  end

  tests("#list_tags_for_stream").formats(AWS::Kinesis::Formats::LIST_TAGS_FOR_STREAM_FORMAT) do
    Fog::AWS[:kinesis].list_tags_for_stream("StreamName" => @stream_id).body.tap do |body|
      returns({"a" => "1", "b" => "2"}) {
        body["Tags"].inject({}){ |m, tag| m.merge(tag["Key"] => tag["Value"]) }
      }
    end
  end

  tests("#remove_tags_from_stream").returns("") do
    Fog::AWS[:kinesis].remove_tags_from_stream("StreamName" => @stream_id, "TagKeys" => %w[b]).body.tap do
      returns({"a" => "1"}) {
        body = Fog::AWS[:kinesis].list_tags_for_stream("StreamName" => @stream_id).body
        body["Tags"].inject({}){ |m, tag| m.merge(tag["Key"] => tag["Value"]) }
      }
    end
  end

  tests("#delete_stream").returns("") do
    Fog::AWS[:kinesis].delete_stream("StreamName" => @stream_id).body
  end

end
