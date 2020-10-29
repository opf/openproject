Shindo.tests('Fog::Compute[:aws] | volume', ['aws']) do
  @server = Fog::Compute[:aws].servers.create
  @server.wait_for { ready? }

  model_tests(
    Fog::Compute[:aws].volumes,
    {
      availability_zone: @server.availability_zone,
      size: 1,
      tags: { 'key' => 'value' },
      type: 'gp2',
      server: @server,
      device: '/dev/sdz1'
    },
    true
  ) do

    tests('attached').succeeds do
      @instance.server == @server
    end

    tests('#detach').succeeds do
      @instance.detach
      @instance.wait_for { ready? }
      @instance.server.nil?
    end

    tests('#server=').raises(NoMethodError, 'use Fog::AWS::Compute::Volume#attach(server, device)') do
      @instance.server = @server
    end

    tests('#attach(server, device)').succeeds do
      @instance.attach(@server, '/dev/sdz1')
      @instance.server == @server
    end

    tests('#force_detach').succeeds do
      @instance.force_detach
      @instance.wait_for { ready? }
      @instance.server.nil?
    end

    @instance.type = 'io1'
    @instance.iops = 5000
    @instance.size = 100
    @instance.save

    returns(true) { @instance.modification_in_progress? }
    @instance.wait_for { !modification_in_progress? }

    # avoid weirdness with merge_attributes
    @instance = Fog::Compute[:aws].volumes.get(@instance.identity)

    returns('io1') { @instance.type }
    returns(5000)  { @instance.iops }
    returns(100)   { @instance.size }

    tests('@instance.tags').returns({'key' => 'value'}) do
      @instance.tags
    end
  end

  @server.destroy

end
