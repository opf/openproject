class AWS
  class Lambda
    module Formats
      require 'zip'

      GET_FUNCTION_CONFIGURATION = {
        'CodeSize'     => Integer,
        'Description'  => Fog::Nullable::String,
        'FunctionArn'  => String,
        'FunctionName' => String,
        'Handler'      => String,
        'LastModified' => Time,
        'MemorySize'   => Integer,
        'Role'         => String,
        'Runtime'      => String,
        'Timeout'      => Integer
      }
      LIST_FUNCTIONS = {
        'Functions'  => [GET_FUNCTION_CONFIGURATION],
        'NextMarker' => Fog::Nullable::String
      }
      GET_FUNCTION = {
        'Code' => {
          'Location'       => String,
          'RepositoryType' => String
        },
        'Configuration' => GET_FUNCTION_CONFIGURATION
      }
      UPDATE_FUNCTION_CONFIGURATION = GET_FUNCTION_CONFIGURATION
      UPDATE_FUNCTION_CODE          = GET_FUNCTION_CONFIGURATION
      CREATE_FUNCTION               = GET_FUNCTION_CONFIGURATION
      ADD_PERMISSION = {
        'Statement' => {
          'Condition' => Fog::Nullable::Hash,
          'Action'    => Array,
          'Resource'  => String,
          'Effect'    => String,
          'Principal' => Hash,
          'Sid'       => String
        }
      }
      GET_POLICY = {
        'Policy' => {
          'Version'   => String,
          'Id'        => String,
          'Statement' => [ADD_PERMISSION['Statement']]
        }
      }
      GET_EVENT_SOURCE_MAPPING = {
        'BatchSize'             => Integer,
        'EventSourceArn'        => String,
        'FunctionArn'           => String,
        'LastModified'          => Float,
        'LastProcessingResult'  => String,
        'State'                 => String,
        'StateTransitionReason' => String,
        'UUID'                  => String
      }
      LIST_EVENT_SOURCE_MAPPINGS = {
        'EventSourceMappings' => [GET_EVENT_SOURCE_MAPPING],
        'NextMarker'          => Fog::Nullable::String
      }
      CREATE_EVENT_SOURCE_MAPPING = GET_EVENT_SOURCE_MAPPING
      UPDATE_EVENT_SOURCE_MAPPING = GET_EVENT_SOURCE_MAPPING
      DELETE_EVENT_SOURCE_MAPPING = GET_EVENT_SOURCE_MAPPING

      def self.zip(data, filename='index.js')
        data_io = Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry(filename)
          zio.write(data)
        end
        data_io.rewind
        data_io.sysread
      end
    end
    module Samples
      FUNCTION_1 = File.dirname(__FILE__) + '/function_sample_1.js'
      FUNCTION_2 = File.dirname(__FILE__) + '/function_sample_2.js'
    end
  end
end
