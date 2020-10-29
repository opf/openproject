class AWS
  module DNS
    module Formats
      RESOURCE_RECORD_SET = {
        "ResourceRecords" => Array,
        "Name" => String,
        "Type" => String,
        "AliasTarget"=> Fog::Nullable::Hash,
        "TTL" => Fog::Nullable::String
      }

      LIST_RESOURCE_RECORD_SETS = {
        "ResourceRecordSets" => [RESOURCE_RECORD_SET],
        "IsTruncated" => Fog::Boolean,
        "MaxItems" => Integer,
        "NextRecordName" => Fog::Nullable::String,
        "NextRecordType" => Fog::Nullable::String
      }
    end
  end
end
