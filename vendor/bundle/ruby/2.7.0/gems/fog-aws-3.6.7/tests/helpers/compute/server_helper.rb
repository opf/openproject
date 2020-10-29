def server_tests(connection, params = {}, mocks_implemented = true)
  model_tests(connection.servers, params, mocks_implemented) do
    tests('#reload').returns(true) do
      pending if Fog.mocking? && !mocks_implemented
      @instance.wait_for { ready? }
      identity = @instance.identity
      !identity.nil? && identity == @instance.reload.identity
    end

    responds_to(%i[ready state])
    yield if block_given?

    tests('#reboot').succeeds do
      pending if Fog.mocking? && !mocks_implemented
      @instance.wait_for { ready? }
      @instance.reboot
    end

    if !Fog.mocking? || mocks_implemented
      @instance.wait_for { ready? }
    end
  end
end
