class AWS
  module DataPipeline
    module Formats
      BASIC = {
        'pipelineId' => String,
      }

      FIELDS = [
        {
          "key" => String,
          "refValue" => Fog::Nullable::String,
          "stringValue" => Fog::Nullable::String,
        }
      ]

      LIST_PIPELINES = {
        "hasMoreResults" => Fog::Nullable::Boolean,
        "marker" => Fog::Nullable::String,
        "pipelineIdList" => [
          {
            "id" => String,
            "name" => String,
          }
        ]
      }

      QUERY_OBJECTS = {
        "hasMoreResults" => Fog::Nullable::Boolean,
        "marker" => Fog::Nullable::String,
        "ids" => Fog::Nullable::Array,
      }

      DESCRIBE_OBJECTS = {
        "hasMoreResults" => Fog::Nullable::Boolean,
        "marker" => Fog::Nullable::String,
        "pipelineObjects" => [
          {
            "fields" => [
              {
                'id' => String,
                'name' => String,
                'fields' => FIELDS,
              }
            ]
          }
        ]
      }

      DESCRIBE_PIPELINES = {
        "pipelineDescriptionList" => [
          {
            "description" => Fog::Nullable::String,
            "name" => String,
            "pipelineId" => String,
            "fields" => FIELDS,
          }
        ]
      }

      PUT_PIPELINE_DEFINITION = {
        "errored" => Fog::Boolean,
        "validationErrors" => Fog::Nullable::Array,
      }

      GET_PIPELINE_DEFINITION = {
        "pipelineObjects" => [
          {
            "id" => String,
            "name" => String,
            "fields" => FIELDS,
          }
        ],
        "parameterObjects" => Fog::Nullable::Array,
        "parameterValues" => Fog::Nullable::Array,
      }
    end
  end
end
