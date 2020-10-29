Shindo.tests("AWS::RDS | tagging", ['aws', 'rds']) do

  @server = Fog::AWS[:rds].servers.create(rds_default_server_params)
  Fog::Formatador.display_line "Creating RDS instance #{@server.id}"
  Fog::Formatador.display_line "Waiting for instance #{@server.id} to be ready"
  @server.wait_for { ready? }

  tags1 = {'key1' => 'val1'}
  tags2 = {'key2' => 'val2'}

  tests "add and remove tags from a running RDS model" do
    returns({})                 { @server.tags }
    returns(tags1)              { @server.add_tags tags1 }
    returns(tags1.merge tags2)  { @server.add_tags tags2 }
    returns(tags2)              { @server.remove_tags tags1.keys  }
    returns(tags2)              { @server.tags }
  end

  @server.destroy
end
