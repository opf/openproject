Shindo.tests("Fog::AWS[:beanstalk] | environment", ['aws', 'beanstalk']) do

  pending if Fog.mocking?

  @beanstalk = Fog::AWS[:beanstalk]

  @application_name = uniq_id('fog-test-app')
  @environment_name = uniq_id('fog-test-env')
  @version_names = []
  # Create two unique version names
  2.times {
    @version_names << uniq_id('fog-test-version')
  }

  @application = @beanstalk.applications.create({:name => @application_name})

  @versions = []
  @version_names.each { |name|
    @versions << @beanstalk.versions.create({
                                                :label => name,
                                                :application_name => @application_name,
                                            })
  }

  @environment_opts = {
      :application_name => @application_name,
      :name => @environment_name,
      :version_label => @version_names[0],
      :solution_stack_name => '32bit Amazon Linux running Tomcat 7'
  }

  # Note: These model tests can take quite a bit of time to run, about 10 minutes typically.
  model_tests(@beanstalk.environments, @environment_opts, false) do
    # Wait for initial ready before next tests.
    tests("#ready?").succeeds do
      @instance.wait_for { ready? }
    end

    tests("#healthy?").succeeds do
      @instance.wait_for { healthy? }
    end

    test("#events") do
      # There should be some events now.
      @instance.events.length > 0
    end

    test("#version") do
      @instance.version.label == @version_names[0]
    end

    test("#version= string") do
      # Set to version 2
      @instance.version = @version_names[1]

      count = 0
      if @instance.version.label == @version_names[1]
        @instance.events.each { |event|
          if event.message == "Environment update is starting."
            count = count + 1
          end
        }
      end

      count == 1
    end

    tests("#ready? after version= string").succeeds do
      @instance.wait_for { ready? }
    end

    test("#version= version object") do
      # reset back to first version using version object
      @instance.version = @versions[0]

      count = 0
      if @instance.version.label == @version_names[0]
        @instance.events.each { |event|
          if event.message == "Environment update is starting."
            count = count + 1
          end
        }
      end

      # Pass if we have two environment updating events
      count == 2
    end

    tests("#ready? after version= version object").succeeds do
      @instance.wait_for { ready? }
    end

    test('#restart_app_server') do
      @instance.restart_app_server

      passed = false
      @instance.events.each { |event|
        if event.message == "restartAppServer is starting."
          passed = true
        end
      }
      passed
    end

    test('#rebuild') do
      @instance.rebuild
      passed = false
      @instance.events.each { |event|
        if event.message == "rebuildEnvironment is starting."
          passed = true
        end
      }
      passed
    end

    # Wait for ready or next tests may fail
    tests("#ready? after rebuild").succeeds do
      @instance.wait_for { ready? }
    end

  end

  # Wait for instance to terminate before deleting application
  tests('#terminated?').succeeds do
    @instance.wait_for { terminated? }
  end

  # delete application
  @application.destroy

end
