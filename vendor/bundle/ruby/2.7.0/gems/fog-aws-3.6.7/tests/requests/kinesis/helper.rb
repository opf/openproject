class AWS
  module Kinesis

    def wait_for(&block)
      Fog.wait_for do
        block.call.tap do
          print '.'
        end
      end
    end

    def wait_for_status(stream_name, status)
      wait_for do
        Fog::AWS[:kinesis].describe_stream("StreamName" => stream_name).body["StreamDescription"]["StreamStatus"] == status
      end
    end

    def delete_if_exists(stream_name)
      if Fog::AWS[:kinesis].list_streams.body["StreamNames"].include?(stream_name)
        wait_for_status(stream_name, "ACTIVE")
        Fog::AWS[:kinesis].delete_stream("StreamName" => @stream_id)
        wait_for do
          begin
            Fog::AWS[:kinesis].describe_stream("StreamName" => stream_name)
            false
          rescue Fog::AWS::Kinesis::ResourceNotFound
            true
          end
        end
      end
    end

    module Formats # optional keys are commented out

      LIST_STREAMS_FORMAT = {
        "HasMoreStreams" => Fog::Boolean,
        "StreamNames" => [
          String
        ]
      }

      DESCRIBE_STREAM_FORMAT = {
        "StreamDescription" => {
          "HasMoreShards" => Fog::Boolean,
          "Shards" => [
            {
              #"AdjacentParentShardId" => String,
              "HashKeyRange" => {
                "EndingHashKey" => String,
                "StartingHashKey" => String
              },
              #"ParentShardId" => String,
              "SequenceNumberRange" => {
                # "EndingSequenceNumber" => String,
                "StartingSequenceNumber" => String
              },
              "ShardId" => String
            }
          ],
          "StreamARN" => String,
          "StreamName" => String,
          "StreamStatus" => String
        }
      }

      GET_SHARD_ITERATOR_FORMAT = {
        "ShardIterator" => String
      }

      PUT_RECORDS_FORMAT = {
        "FailedRecordCount" => Integer,
        "Records" => [
          {
            # "ErrorCode" => String,
            # "ErrorMessage" => String,
            "SequenceNumber" => String,
            "ShardId" => String
          }
        ]
      }

      PUT_RECORD_FORMAT = {
        "SequenceNumber" => String,
        "ShardId" => String
      }

      GET_RECORDS_FORMAT = {
        "MillisBehindLatest" => Integer,
        "NextShardIterator" => String,
        "Records" => [
          {
            "Data" => String,
            "PartitionKey" => String,
            "SequenceNumber" => String
          }
        ]
      }

      LIST_TAGS_FOR_STREAM_FORMAT = {
        "HasMoreTags" => Fog::Boolean,
        "Tags" => [
          {
            "Key" => String,
            "Value" => String
          }
        ]
      }

    end
  end
end
