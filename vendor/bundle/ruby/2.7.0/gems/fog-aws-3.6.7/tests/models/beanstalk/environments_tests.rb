Shindo.tests("Fog::AWS[:beanstalk] | environments", ['aws', 'beanstalk']) do

  pending if Fog.mocking?

  @beanstalk = Fog::AWS[:beanstalk]

  @application_name = uniq_id('fog-test-app')
  @environment_name = uniq_id('fog-test-env')
  @version_name = uniq_id('fog-test-version')

  # Create an application/version to use for testing.
  @version = @beanstalk.versions.create({
      :label => @version_name,
      :application_name => @application_name,
      :auto_create_application => true
                             })

  @application = @beanstalk.applications.get(@application_name)

  @environment_opts = {
      :application_name => @application_name,
      :name => @environment_name,
      :version_label => @version_name,
      :solution_stack_name => '32bit Amazon Linux running Tomcat 7'
  }

  collection_tests(@beanstalk.environments, @environment_opts, false)

  # Wait for instance to terminate before deleting application
  @instance.wait_for { terminated? }
  # delete application
  @application.destroy

end
