Shindo.tests("Fog::AWS[:beanstalk] | application", ['aws', 'beanstalk']) do

  pending if Fog.mocking?

  @application_opts = {
      :name => uniq_id('fog-test-app'),
      :description => 'A nice description.'
  }

  model_tests(Fog::AWS[:beanstalk].applications, @application_opts, false) do

    test("#attributes") do
      @instance.name == @application_opts[:name] &&
          @instance.description == @application_opts[:description]
    end

    test("#events") do
      # There should be some events now.
      @instance.events.length > 0
    end

    version_name = uniq_id('fog-test-ver')
    @instance.versions.create(
        :application_name => @instance.name,
        :label => version_name
    )

    test("#versions") do
      # We should have one version.
      @instance.versions.length == 1
    end

    template_name = uniq_id('fog-test-template')
    @instance.templates.create(
        :application_name => @instance.name,
        :name => template_name,
        :solution_stack_name => '32bit Amazon Linux running Tomcat 7'
    )

    test('#templates') do
      # We should have one template now.
      @instance.templates.length == 1
    end

    environment_name = uniq_id('fog-test-env')
    environment = @instance.environments.create(
        :application_name => @instance.name,
        :name => environment_name,
        :version_label => version_name,
        :solution_stack_name => '32bit Amazon Linux running Tomcat 7'
    )

    # Go ahead an terminate immediately.
    environment.destroy

    # Create an environment
    test("#environments") do
      # We should have one environment now.
      @instance.environments.length == 1
    end

    # Must wait for termination before destroying application
    tests("waiting for test environment to terminate").succeeds do
      environment.wait_for { terminated? }
    end

  end

end
