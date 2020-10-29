class AWS
  module KMS
    module Formats
      BASIC = {
        'ResponseMetadata' => { 'RequestId' => String }
      }

      DESCRIBE_KEY = {
        "KeyMetadata" => {
          "KeyUsage"     => String,
          "AWSAccountId" => String,
          "KeyId"        => String,
          "Description"  => Fog::Nullable::String,
          "CreationDate" => Time,
          "Arn"          => String,
          "Enabled"      => Fog::Boolean
        }
      }

      LIST_KEYS = {
        "Keys"      => [{ "KeyId" => String, "KeyArn" => String }],
        "Truncated" => Fog::Boolean,
        "Marker"    => Fog::Nullable::String
      }
    end
  end
end
