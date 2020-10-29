Shindo.tests('Fog::AWS[:dynamodb] | item requests', ['aws']) do

  @table_name = "fog_table_#{Time.now.to_f.to_s.gsub('.','')}"

  unless Fog.mocking?
    Fog::AWS[:dynamodb].create_table(
      @table_name,
      {'HashKeyElement' => {'AttributeName' => 'key', 'AttributeType' => 'S'}},
      {'ReadCapacityUnits' => 5, 'WriteCapacityUnits' => 5}
    )
    Fog.wait_for { Fog::AWS[:dynamodb].describe_table(@table_name).body['Table']['TableStatus'] == 'ACTIVE' }
  end

  tests('success') do

    tests("#put_item('#{@table_name}', {'key' => {'S' => 'key'}}, {'value' => {'S' => 'value'}})").formats('ConsumedCapacityUnits' => Float) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].put_item(@table_name, {'key' => {'S' => 'key'}}, {'value' => {'S' => 'value'}}).body
    end

    tests("#update_item('#{@table_name}', {'HashKeyElement' => {'S' => 'key'}}, {'value' => {'Value' => {'S' => 'value'}}})").formats('ConsumedCapacityUnits' => Float) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].update_item(@table_name, {'HashKeyElement' => {'S' => 'key'}}, {'value' => {'Value' => {'S' => 'value'}}}).body
    end

    @batch_get_item_format = {
      'Responses' => {
        @table_name => {
          'ConsumedCapacityUnits' => Float,
          'Items' => [{
            'key'   => { 'S' => String },
            'value' => { 'S' => String }
          }]
        }
      },
      'UnprocessedKeys' => {}
    }

    tests("#batch_get_item({'#{@table_name}' => {'Keys' => [{'HashKeyElement' => {'S' => 'key'}}]}})").formats(@batch_get_item_format) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].batch_get_item(
        {@table_name => {'Keys' => [{'HashKeyElement' => {'S' => 'key'}}]}}
      ).body
    end

    @batch_put_item_format = {
      'Responses'=> {
        @table_name => {
          'ConsumedCapacityUnits' => Float}
      },
      'UnprocessedItems'=> {}
    }

    tests("#batch_put_item({ '#{@table_name}' => [{ 'PutRequest' => { 'Item' =>
            { 'HashKeyElement' => { 'S' => 'key' }, 'RangeKeyElement' => { 'S' => 'key' }}}}]})"
         ).formats(@batch_put_item_format) do
            pending if Fog.mocking?
            Fog::AWS[:dynamodb].batch_put_item(
              {@table_name => [{'PutRequest'=> {'Item'=>
                {'HashKeyElement' => { 'S' => 'key' },
                 'RangeKeyElement' => { 'S' => 'key' }
                }}}]}
            ).body
         end

    @get_item_format = {
      'ConsumedCapacityUnits' => Float,
      'Item' => {
        'key'   => { 'S' => String },
        'value' => { 'S' => String }
      }
    }

    tests("#get_item('#{@table_name}', {'HashKeyElement' => {'S' => 'key'}})").formats(@get_item_format) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].get_item(@table_name, {'HashKeyElement' => {'S' => 'key'}}).body
    end

    tests("#get_item('#{@table_name}', {'HashKeyElement' => {'S' => 'notakey'}})").formats('ConsumedCapacityUnits' => Float) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].get_item(@table_name, {'HashKeyElement' => {'S' => 'notakey'}}).body
    end

    @query_format = {
      'ConsumedCapacityUnits' => Float,
      'Count'                 => Integer,
      'Items'                 => [{
        'key'   => { 'S' => String },
        'value' => { 'S' => String }
      }],
      'LastEvaluatedKey'      => NilClass
    }

    tests("#query('#{@table_name}')").formats(@query_format) do
      pending if Fog.mocking?
      pending # requires a table with range key
      Fog::AWS[:dynamodb].query(@table_name).body
    end

    @scan_format = @query_format.merge('ScannedCount' => Integer)

    tests("scan('#{@table_name}')").formats(@scan_format) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].scan(@table_name).body
    end

    tests("#delete_item('#{@table_name}', {'HashKeyElement' => {'S' => 'key'}})").formats('ConsumedCapacityUnits' => Float) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].delete_item(@table_name, {'HashKeyElement' => {'S' => 'key'}}).body
    end

    tests("#delete_item('#{@table_name}, {'HashKeyElement' => {'S' => 'key'}})").formats('ConsumedCapacityUnits' => Float) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].delete_item(@table_name, {'HashKeyElement' => {'S' => 'key'}}).body
    end

  end

  tests('failure') do

    tests("#put_item('notatable', {'key' => {'S' => 'key'}}, {'value' => {'S' => 'value'}})").raises(Excon::Errors::BadRequest) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].put_item('notatable', {'key' => {'S' => 'key'}}, {'value' => {'S' => 'value'}})
    end

    tests("#update_item('notatable', {'HashKeyElement' => {'S' => 'key'}}, {'value' => {'Value' => {'S' => 'value'}}})").raises(Excon::Errors::BadRequest) do
      pending if Fog.mocking?
      Fog::AWS[:dynamodb].update_item('notatable', {'HashKeyElement' => {'S' => 'key'}}, {'value' => {'Value' => {'S' => 'value'}}})
    end

  end

  unless Fog.mocking?
    Fog::AWS[:dynamodb].delete_table(@table_name)
  end

end
