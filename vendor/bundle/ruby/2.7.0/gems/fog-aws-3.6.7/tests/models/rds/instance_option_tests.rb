Shindo.tests("AWS::RDS | db instance options", ['aws', 'rds']) do

  params = {:engine => 'mysql'}

  pending if Fog.mocking?

  tests('#options') do
    tests 'contains options' do
      @instance = Fog::AWS[:rds].instance_options.new(params)
      returns(true) { @instance.engine == 'mysql' }
    end
  end

end
