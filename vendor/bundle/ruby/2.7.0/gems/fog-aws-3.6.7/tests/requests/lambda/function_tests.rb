Shindo.tests('AWS::Lambda | function requests', ['aws', 'lambda']) do

  _lambda    = Fog::AWS[:lambda]
  account_id = _lambda.account_id
  region     = _lambda.region

  function1 = IO.read(AWS::Lambda::Samples::FUNCTION_1)
  function2 = IO.read(AWS::Lambda::Samples::FUNCTION_2)
  zipped_function1 = Base64::encode64(AWS::Lambda::Formats.zip(function1))
  zipped_function2 = Base64::encode64(AWS::Lambda::Formats.zip(function2))

  function1_arn     = nil
  function1_name    = 'function1'
  function2_name    = 'function2'
  function1_handler = 'index.handler'

  function_role = 'arn:aws:iam::647975416665:role/lambda_basic_execution'

  sns_principal      = 'sns.amazonaws.com'
  sns_topic_sid      = Fog::Mock.random_letters_and_numbers(32)
  sns_allowed_action = 'lambda:invoke'
  sns_topic_arn      = Fog::AWS::Mock.arn('sns', account_id, 'mock_topic', region)

  kinesis_stream_arn = Fog::AWS::Mock.arn('kinesis', account_id, 'mock_stream', region)
  event_source_mapping1_id = nil

  tests('success') do

    tests('#list_functions').formats(AWS::Lambda::Formats::LIST_FUNCTIONS) do
      result = _lambda.list_functions.body
      functions = result['Functions']
      returns(true) { functions.empty? }
      result
    end

    tests('#create_function').formats(AWS::Lambda::Formats::CREATE_FUNCTION) do
      description = 'a copy of my first function'

      result = _lambda.create_function(
        'FunctionName' => function1_name,
        'Handler'      => function1_handler,
        'Role'         => function_role,
        'Description'  => description,
        'Code'         => { 'ZipFile' => zipped_function1 }
      ).body

      returns(true) { result.has_key?('FunctionArn')              }
      returns(true) { result['CodeSize'] > 0                      }
      returns(true) { result['MemorySize'] >= 128                 }
      returns(true) { result['FunctionName'].eql?(function1_name) }
      returns(true) { result['Handler'].eql?(function1_handler)   }

      function1_arn = result['FunctionArn']
      result
    end

    tests('#invoke') do
      payload = { 'value1' => 2, 'value2' => 42 }

      result = _lambda.invoke(
        'FunctionName' => function1_name,
        'Payload'      => payload
      ).body

      returns(false) { result.length.zero? }
      returns(false) { result.match(/function:#{function1_name} was invoked/).nil? }

      result
    end

    tests('#get_function').formats(AWS::Lambda::Formats::GET_FUNCTION) do
      result = _lambda.get_function('FunctionName' => function1_name).body
      func_config = result['Configuration']

      returns(false) { result['Code']['Location'].match(/^https:\/\/awslambda-/).nil? }
      returns(true)  { func_config.has_key?('FunctionArn')              }
      returns(true)  { func_config['CodeSize'] > 0                      }
      returns(true)  { func_config['MemorySize'] >= 128                 }
      returns(true)  { func_config['FunctionName'].eql?(function1_name) }
      returns(true)  { func_config['Handler'].eql?(function1_handler)   }
      returns(true)  { func_config['FunctionArn'].eql?(function1_arn)   }

      result
    end

    tests('#get_function_configuration').formats(AWS::Lambda::Formats::GET_FUNCTION_CONFIGURATION) do
      result = _lambda.get_function_configuration(
        'FunctionName' => function1_name).body

      returns(true)  { result.has_key?('FunctionArn')              }
      returns(true)  { result['CodeSize'] > 0                      }
      returns(true)  { result['MemorySize'] >= 128                 }
      returns(true)  { result['FunctionName'].eql?(function1_name) }
      returns(true)  { result['Handler'].eql?(function1_handler)   }
      returns(true)  { result['FunctionArn'].eql?(function1_arn)   }

      result
    end

    tests('#update_function_configuration').formats(AWS::Lambda::Formats::UPDATE_FUNCTION_CONFIGURATION) do
      new_memory_size = 256
      new_description = "this function does nothing, just let's call it foobar"
      new_timeout     = 10

      result = _lambda.update_function_configuration(
        'FunctionName' => function1_name,
        'MemorySize'   => new_memory_size,
        'Description'  => new_description,
        'Timeout'      => new_timeout
      ).body

      returns(true)  { result['CodeSize'] > 0                       }
      returns(true)  { result['MemorySize'].eql?(new_memory_size)   }
      returns(true)  { result['FunctionArn'].eql?(function1_arn)    }
      returns(true)  { result['Description'].eql?(new_description)  }
      returns(true)  { result['Timeout'].eql?(new_timeout)          }

      result
    end

    tests('#update_function_code').formats(AWS::Lambda::Formats::UPDATE_FUNCTION_CODE) do
      result = _lambda.update_function_code(
        'FunctionName' => function1_name,
        'ZipFile'      => zipped_function2
      ).body

      returns(true) { result.has_key?('FunctionArn')              }
      returns(true) { result['CodeSize'] > 0                      }
      returns(true) { result['MemorySize'] >= 128                 }
      returns(true) { result['FunctionName'].eql?(function1_name) }
      returns(true) { result['Handler'].eql?(function1_handler)   }

      result
    end

    tests('#add_permission').formats(AWS::Lambda::Formats::ADD_PERMISSION) do
      params = {
        'FunctionName' => function1_name,
        'Principal'    => sns_principal,
        'StatementId'  => sns_topic_sid,
        'Action'       => sns_allowed_action,
        'SourceArn'    => sns_topic_arn
      }
      result = _lambda.add_permission(params).body
      statement = result['Statement']

      returns(true)  { statement['Action'].include?(sns_allowed_action)      }
      returns(true)  { statement['Principal']['Service'].eql?(sns_principal) }
      returns(true)  { statement['Sid'].eql?(sns_topic_sid)                  }
      returns(true)  { statement['Resource'].eql?(function1_arn)             }
      returns(true)  { statement['Effect'].eql?('Allow')                     }
      returns(false) { statement['Condition'].empty?                         }

      result
    end

    tests('#get_policy').formats(AWS::Lambda::Formats::GET_POLICY) do
      result = _lambda.get_policy('FunctionName' => function1_name).body
      policy = result['Policy']

      returns(false) { policy['Statement'].empty? }

      statement = policy['Statement'].first

      returns(true)  { statement['Action'].include?(sns_allowed_action)      }
      returns(true)  { statement['Principal']['Service'].eql?(sns_principal) }
      returns(true)  { statement['Sid'].eql?(sns_topic_sid)                  }
      returns(true)  { statement['Resource'].eql?(function1_arn)             }
      returns(true)  { statement['Effect'].eql?('Allow')                     }
      returns(false) { statement['Condition'].empty?                         }

      result
    end

    tests('#remove_permission') do
      params = {
        'FunctionName' => function1_name,
        'StatementId'  => sns_topic_sid
      }
      result = _lambda.remove_permission(params).body

      returns(true) { result.empty? }

      raises(Fog::AWS::Lambda::Error) do
        _lambda.get_policy('FunctionName' => function1_name)
      end

      result
    end

    tests('#create_event_source_mapping').formats(AWS::Lambda::Formats::CREATE_EVENT_SOURCE_MAPPING) do
      params = {
        'FunctionName'     => function1_name,
        'EventSourceArn'   => kinesis_stream_arn,
        'Enabled'          => true,
        'StartingPosition' => 'TRIM_HORIZON'
      }
      result = _lambda.create_event_source_mapping(params).body

      returns(true) { result['BatchSize'] > 0                             }
      returns(true) { result['EventSourceArn'].eql?(kinesis_stream_arn)   }
      returns(true) { result['FunctionArn'].eql?(function1_arn)           }
      returns(true) { result['LastProcessingResult'].eql?('No records processed') }
      returns(true) { result['State'].eql?('Creating')                    }
      returns(true) { result['StateTransitionReason'].eql?('User action') }

      event_source_mapping1_id = result['UUID']
      result
    end

    tests('#list_event_source_mappings').formats(AWS::Lambda::Formats::LIST_EVENT_SOURCE_MAPPINGS) do
      params = { 'FunctionName' => function1_name }
      result = _lambda.list_event_source_mappings(params).body
      event_source_mappings = result['EventSourceMappings']
      returns(false) { event_source_mappings.empty? }
      mapping = event_source_mappings.first
      returns(true) { mapping['UUID'].eql?(event_source_mapping1_id) }
      result
    end

    tests('#get_event_source_mapping').formats(AWS::Lambda::Formats::GET_EVENT_SOURCE_MAPPING) do
      params = { 'UUID' => event_source_mapping1_id }
      result = _lambda.get_event_source_mapping(params).body

      returns(true) { result['BatchSize'] > 0                             }
      returns(true) { result['EventSourceArn'].eql?(kinesis_stream_arn)   }
      returns(true) { result['FunctionArn'].eql?(function1_arn)           }
      returns(true) { result['LastProcessingResult'].eql?('OK')           }
      returns(true) { result['State'].eql?('Enabled')                     }
      returns(true) { result['StateTransitionReason'].eql?('User action') }
      returns(true) { result['UUID'].eql?(event_source_mapping1_id)       }

      result
    end

    tests('#update_event_source_mapping').formats(AWS::Lambda::Formats::UPDATE_EVENT_SOURCE_MAPPING) do
      new_batch_size  = 500
      enabled_mapping = false
      params = {
        'UUID'      => event_source_mapping1_id,
        'BatchSize' => new_batch_size,
        'Enabled'   => enabled_mapping
      }
      result = _lambda.update_event_source_mapping(params).body

      returns(true) { result['BatchSize'].eql?(new_batch_size)            }
      returns(true) { result['EventSourceArn'].eql?(kinesis_stream_arn)   }
      returns(true) { result['FunctionArn'].eql?(function1_arn)           }
      returns(true) { result['LastProcessingResult'].eql?('OK')           }
      returns(true) { result['State'].eql?('Disabling')                   }
      returns(true) { result['StateTransitionReason'].eql?('User action') }
      returns(true) { result['UUID'].eql?(event_source_mapping1_id)       }

      result
    end

    tests('#delete_event_source_mapping').formats(AWS::Lambda::Formats::DELETE_EVENT_SOURCE_MAPPING) do
      params = { 'UUID' => event_source_mapping1_id }
      result = _lambda.delete_event_source_mapping(params).body
      returns(true) { result['BatchSize'] > 0                             }
      returns(true) { result['EventSourceArn'].eql?(kinesis_stream_arn)   }
      returns(true) { result['FunctionArn'].eql?(function1_arn)           }
      returns(false) { result['LastProcessingResult'].empty?              }
      returns(true) { result['State'].eql?('Deleting')                    }
      returns(true) { result['StateTransitionReason'].eql?('User action') }
      returns(true) { result['UUID'].eql?(event_source_mapping1_id)       }
      result
    end

    tests('#list_event_source_mappings again').formats(AWS::Lambda::Formats::LIST_EVENT_SOURCE_MAPPINGS) do
      params = { 'FunctionName' => function1_name }
      result = _lambda.list_event_source_mappings(params).body
      event_source_mappings = result['EventSourceMappings']
      returns(true) { event_source_mappings.empty? }
      result
    end

    tests('#delete_function') do
      result = _lambda.delete_function('FunctionName' => function1_name).body

      returns(true) { result.empty? }

      raises(Fog::AWS::Lambda::Error) do
        _lambda.get_function('FunctionName' => function1_name)
      end

      result
    end

    tests('#list_functions again').formats(AWS::Lambda::Formats::LIST_FUNCTIONS) do
      result = _lambda.list_functions.body
      functions = result['Functions']
      returns(true) { functions.empty? }
      result
    end

    tests('#create_function for failures tests').formats(AWS::Lambda::Formats::CREATE_FUNCTION) do
      description = 'failure tests function'

      result = _lambda.create_function(
        'FunctionName' => function2_name,
        'Handler'      => function1_handler,
        'Role'         => function_role,
        'Description'  => description,
        'Code'         => { 'ZipFile' => zipped_function1 }
      ).body

      returns(true) { result.has_key?('FunctionArn')              }
      returns(true) { result['CodeSize'] > 0                      }
      returns(true) { result['MemorySize'] >= 128                 }
      returns(true) { result['FunctionName'].eql?(function2_name) }
      returns(true) { result['Handler'].eql?(function1_handler)   }

      result
    end

  end

  tests('failures') do

    tests("#invoke without function name").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.invoke.body
    end

    tests("#invoke nonexistent function").raises(Fog::AWS::Lambda::Error) do
      response = Fog::AWS[:lambda].invoke('FunctionName' => 'nonexistent').body
    end

    tests("#get_function without function name").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_function.body
    end

    tests("#get_function on nonexistent function").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_function('FunctionName' => 'nonexistent').body
    end

    tests("#get_function_configuration without function name").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_function_configuration.body
    end

    tests("#get_function_configuration on nonexistent function").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_function_configuration('FunctionName' => 'nonexistent').body
    end

    tests("update_function_configuration without function name").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.update_function_configuration.body
    end

    tests("#update_function_configuration on nonexistent function").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.update_function_configuration('FunctionName' => 'nonexistent').body
    end

    tests("update_function_code without function name").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.update_function_code.body
    end

    tests("#update_function_code on nonexistent function").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.update_function_code(
        'FunctionName' => 'nonexistent',
        'ZipFile'      => zipped_function2
      ).body
    end

    tests("#update_function_code on valid function without source").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.update_function_code('FunctionName' => 'foobar').body
    end

    tests("#delete_function without params").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.delete_function.body
    end

    tests("#delete_function on nonexistent function").raises(Fog::AWS::Lambda::Error) do
      response = _lambda.delete_function('FunctionName' => 'nonexistent').body
    end

    tests('#get_policy without params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_policy.body
    end

    tests('#get_policy on nonexistent function').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_policy('FunctionName' => 'nonexistent').body
    end

    tests('#get_policy on function without permissions').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_policy('FunctionName' => function2_name).body
    end

    tests('#add_permission without params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.add_permission.body
    end

    tests('#add_permission on nonexistent function').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.add_permission('FunctionName' => 'nonexistent').body
    end

    tests('#add_permission with missing params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.add_permission('FunctionName' => function2_name).body
    end

    tests('#remove_permission without params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.remove_permission.body
    end

    tests('#remove_permission on nonexistent function').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.remove_permission('FunctionName' => 'nonexistent').body
    end

    tests('#remove_permission on function with missing sid param').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_policy('FunctionName' => function2_name).body
    end

    tests('#remove_permission on function with missing sid param').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_policy(
        'FunctionName' => function2_name,
        'StatementId'  => 'nonexistent_statement_id'
      ).body
    end

    tests('#create_event_source_mapping without params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.create_event_source_mapping.body
    end

    tests('#create_event_source_mapping on nonexistent function').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.create_event_source_mapping('FunctionName' => 'nonexistent').body
    end

    tests('#create_event_source_mapping with missing params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.create_event_source_mapping('FunctionName' => function2_name).body
    end

    tests('#get_event_source_mapping without params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.get_event_source_mapping.body
    end

    tests('#get_event_source_mapping nonexistent').raises(Fog::AWS::Lambda::Error) do
      mapping_id = "deadbeef-caca-cafe-cafa-ffffdeadbeef"
      response = _lambda.get_event_source_mapping('UUID' => mapping_id).body
    end

    tests('#update_event_source_mapping without params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.update_event_source_mapping.body
    end

    tests('#update_event_source_mapping nonexistent').raises(Fog::AWS::Lambda::Error) do
      mapping_id = "deadbeef-caca-cafe-cafa-ffffdeadbeef"
      response = _lambda.update_event_source_mapping('UUID' => mapping_id).body
    end

    tests('#delete_event_source_mapping without params').raises(Fog::AWS::Lambda::Error) do
      response = _lambda.delete_event_source_mapping.body
    end

    tests('#delete_event_source_mapping nonexistent').raises(Fog::AWS::Lambda::Error) do
      mapping_id = "deadbeef-caca-cafe-cafa-ffffdeadbeef"
      response = _lambda.create_event_source_mapping('UUID' => mapping_id).body
    end

  end

end
