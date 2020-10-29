Shindo.tests("Fog::Compute[:aws] | address", ['aws']) do

  model_tests(Fog::Compute[:aws].addresses, {}, true) do

    @server = Fog::Compute[:aws].servers.create
    @server.wait_for { ready? }

    tests('#server=').succeeds do
      @instance.server = @server
    end

    tests('#server') do
      test(' == @server') do
        @server.reload
        @instance.server.public_ip_address == @instance.public_ip
      end
    end

    tests("#change_scope") do
      test('to vpc') do
        @instance.change_scope
        @instance.domain == 'vpc'
      end

      test('to classic') do
        @instance.change_scope
        @instance.domain == 'standard'
      end

      # merge_attributes requires this
      @instance = Fog::Compute[:aws].addresses.get(@instance.identity)
    end

    @server.destroy

  end

  model_tests(Fog::Compute[:aws].addresses, { :domain => "vpc" }, true) do
    tests("#change_scope").raises(Fog::AWS::Compute::Error) do
      @instance.change_scope
    end
  end
end
