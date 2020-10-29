class AWS
  module EFS
    module Formats
      FILE_SYSTEM_FORMAT = {
        "CreationTime"         => Float,
        "CreationToken"        => String,
        "FileSystemId"         => String,
        "LifeCycleState"       => String,
        "Name"                 => Fog::Nullable::String,
        "NumberOfMountTargets" => Integer,
        "OwnerId"              => String,
        "PerformanceMode"      => String,
        "Encrypted"            => Fog::Nullable::Boolean,
        "KmsKeyId"             => Fog::Nullable::String,
        "SizeInBytes"          => {
          "Timestamp" => Fog::Nullable::Float,
          "Value"     => Integer
        }
      }

      MOUNT_TARGET_FORMAT = {
        "FileSystemId"       => String,
        "IpAddress"          => String,
        "LifeCycleState"     => String,
        "MountTargetId"      => String,
        "NetworkInterfaceId" => String,
        "OwnerId"            => String,
        "SubnetId"           => String
      }

      DESCRIBE_FILE_SYSTEMS_RESULT = {
        "FileSystems" => [FILE_SYSTEM_FORMAT]
      }

      DESCRIBE_MOUNT_TARGETS_RESULT = {
        "MountTargets" => [MOUNT_TARGET_FORMAT]
      }

      DESCRIBE_MOUNT_TARGET_SECURITY_GROUPS_FORMAT = {
        "SecurityGroups" => Array
      }
    end
  end
end
