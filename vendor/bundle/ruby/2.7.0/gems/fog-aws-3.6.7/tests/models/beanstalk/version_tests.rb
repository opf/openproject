Shindo.tests("Fog::AWS[:beanstalk] | version", ['aws', 'beanstalk']) do

  pending if Fog.mocking?

  @beanstalk = Fog::AWS[:beanstalk]

  @application_name = uniq_id('fog-test-app')
  @version_name = uniq_id('fog-test-version')

  @version_description = 'A nice description'

  @application = @beanstalk.applications.create({:name => @application_name})

  @version_opts = {
      :application_name => @application_name,
      :label => @version_name,
      :description => @version_description
  }

  model_tests(@beanstalk.versions, @version_opts, false) do

    test("attributes") do
      @instance.label == @version_name &&
          @instance.description == @version_description &&
          @instance.application_name == @application_name
    end

    test("#events") do
      # There should be some events now.
      @instance.events.length > 0
    end

    test("#update description") do
      new_description = "A completely new description."
      @instance.description = new_description
      @instance.update

      passed = false
      if @instance.description == new_description
        # reload version from AWS to verify save is committed to server, not just on local object
        if @beanstalk.versions.get(@application_name, @version_name).description == new_description
          passed = true
        end
      end
      passed
    end

    test("#update description empty") do
      @instance.description = '' # Set to empty to nil out
      @instance.update

      passed = false
      if @instance.description == nil
        # reload version from AWS to verify save is committed to server, not just on local object
        if @beanstalk.versions.get(@application_name, @version_name).description == nil
          passed = true
        end
      end
      passed
    end

  end

  # delete application
  @application.destroy
end
