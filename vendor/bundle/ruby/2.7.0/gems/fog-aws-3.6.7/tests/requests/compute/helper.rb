class AWS
  module Compute
    module Formats
      BASIC = {
        'requestId' => String
      }

      DESCRIBE_IMAGES = BASIC.merge({
        "imagesSet" => [{
          "imageId" => String,
          "imageLocation" => String,
          "imageState" => String,
          "imageOwnerId" => String,
          "creationDate" => Fog::Nullable::String,
          "isPublic" => Fog::Nullable::Boolean,
          "architecture" => String,
          "imageType" => String,
          "imageOwnerAlias" => String,
          "rootDeviceType" => String,
          "blockDeviceMapping" => Array,
          "virtualizationType" => String,
          "hypervisor" => String
        }]
      })
    end
  end
end
