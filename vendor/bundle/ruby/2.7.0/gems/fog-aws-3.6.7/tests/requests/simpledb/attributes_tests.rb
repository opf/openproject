Shindo.tests('AWS::SimpleDB | attributes requests', ['aws']) do

  @domain_name = "fog_domain_#{Time.now.to_f.to_s.gsub('.','')}"

  Fog::AWS[:simpledb].create_domain(@domain_name)

  tests('success') do

    tests("#batch_put_attributes('#{@domain_name}', { 'a' => { 'b' => 'c', 'd' => 'e' }, 'x' => { 'y' => 'z' } }).body").formats(AWS::SimpleDB::Formats::BASIC) do
      Fog::AWS[:simpledb].batch_put_attributes(@domain_name, { 'a' => { 'b' => 'c', 'd' => 'e' }, 'x' => { 'y' => 'z' } }).body
    end

    tests("#get_attributes('#{@domain_name}', 'a', {'ConsistentRead' => true}).body['Attributes']").returns({'b' => ['c'], 'd' => ['e']}) do
      Fog::AWS[:simpledb].get_attributes(@domain_name, 'a', {'ConsistentRead' => true}).body['Attributes']
    end

    tests("#get_attributes('#{@domain_name}', 'AttributeName' => 'notanattribute')").succeeds do
      Fog::AWS[:simpledb].get_attributes(@domain_name, 'AttributeName' => 'notanattribute')
    end

    tests("#select('select * from #{@domain_name}', {'ConsistentRead' => true}).body['Items']").returns({'a' => { 'b' => ['c'], 'd' => ['e']}, 'x' => { 'y' => ['z'] } }) do
      pending if Fog.mocking?
      Fog::AWS[:simpledb].select("select * from #{@domain_name}", {'ConsistentRead' => true}).body['Items']
    end

    tests("#put_attributes('#{@domain_name}', 'conditional', { 'version' => '1' }).body").formats(AWS::SimpleDB::Formats::BASIC) do
      Fog::AWS[:simpledb].put_attributes(@domain_name, 'conditional', { 'version' => '1' }).body
    end

    tests("#put_attributes('#{@domain_name}', 'conditional', { 'version' => '2' }, :expect => { 'version' => '1' }, :replace => ['version']).body").formats(AWS::SimpleDB::Formats::BASIC) do
      Fog::AWS[:simpledb].put_attributes(@domain_name, 'conditional', { 'version' => '2' }, :expect => { 'version' => '1' }, :replace => ['version']).body
    end

    # Verify that we can delete individual attributes.
    tests("#delete_attributes('#{@domain_name}', 'a', {'d' => []})").succeeds do
      Fog::AWS[:simpledb].delete_attributes(@domain_name, 'a', {'d' => []}).body
    end

    # Verify that individually deleted attributes are actually removed.
    tests("#get_attributes('#{@domain_name}', 'a', {'AttributeName' => ['d'], 'ConsistentRead' => true}).body['Attributes']").returns({}) do
      Fog::AWS[:simpledb].get_attributes(@domain_name, 'a', {'AttributeName' => ['d'], 'ConsistentRead' => true}).body['Attributes']
    end

    tests("#delete_attributes('#{@domain_name}', 'a').body").formats(AWS::SimpleDB::Formats::BASIC) do
      Fog::AWS[:simpledb].delete_attributes(@domain_name, 'a').body
    end

    # Verify that we can delete entire domain, item combinations.
    tests("#delete_attributes('#{@domain_name}', 'a').body").succeeds do
      Fog::AWS[:simpledb].delete_attributes(@domain_name, 'a').body
    end

    # Verify that deleting a domain, item combination removes all related attributes.
    tests("#get_attributes('#{@domain_name}', 'a', {'ConsistentRead' => true}).body['Attributes']").returns({}) do
      Fog::AWS[:simpledb].get_attributes(@domain_name, 'a', {'ConsistentRead' => true}).body['Attributes']
    end

  end

  tests('failure') do

    tests("#batch_put_attributes('notadomain', { 'a' => { 'b' => 'c' }, 'x' => { 'y' => 'z' } })").raises(Excon::Errors::BadRequest) do
      Fog::AWS[:simpledb].batch_put_attributes('notadomain', { 'a' => { 'b' => 'c' }, 'x' => { 'y' => 'z' } })
    end

    tests("#get_attributes('notadomain', 'a')").raises(Excon::Errors::BadRequest) do
      Fog::AWS[:simpledb].get_attributes('notadomain', 'a')
    end

    tests("#put_attributes('notadomain', 'conditional', { 'version' => '1' })").raises(Excon::Errors::BadRequest) do
      Fog::AWS[:simpledb].put_attributes('notadomain', 'foo', { 'version' => '1' })
    end

    tests("#put_attributes('#{@domain_name}', 'conditional', { 'version' => '2' }, :expect => { 'version' => '1' }, :replace => ['version'])").raises(Excon::Errors::Conflict) do
      Fog::AWS[:simpledb].put_attributes(@domain_name, 'conditional', { 'version' => '2' }, :expect => { 'version' => '1' }, :replace => ['version'])
    end

    tests("#delete_attributes('notadomain', 'a')").raises(Excon::Errors::BadRequest) do
      Fog::AWS[:simpledb].delete_attributes('notadomain', 'a')
    end

  end

  Fog::AWS[:simpledb].delete_domain(@domain_name)

end
