Shindo.tests("Fog::AWS[:beanstalk] | template", ['aws', 'beanstalk']) do

  pending if Fog.mocking?

  @beanstalk = Fog::AWS[:beanstalk]

  @application_name = uniq_id('fog-test-app')
  @template_name = uniq_id('fog-test-template')

  @template_description = 'A nice description'

  @application = @beanstalk.applications.create({:name => @application_name})

  @template_opts = {
      :application_name => @application_name,
      :name => @template_name,
      :description => @template_description,
      :solution_stack_name => '32bit Amazon Linux running Tomcat 7'
  }

  model_tests(@beanstalk .templates, @template_opts, false) do

    test("#attributes") do
      @instance.name == @template_name &&
          @instance.description == @template_description &&
          @instance.application_name == @application_name &&
          @instance.solution_stack_name == @template_opts[:solution_stack_name]
    end

    test("#options") do
      options = @instance.options
      passed = false
      if options.each { |option|
        # See if we recognize at least one option
        if option["Name"] == 'LoadBalancerHTTPPort' && option["Namespace"] == 'aws:elb:loadbalancer'
          passed = true
        end
      }
      end
      passed
    end

  end

  # delete application
  @application.destroy
end
