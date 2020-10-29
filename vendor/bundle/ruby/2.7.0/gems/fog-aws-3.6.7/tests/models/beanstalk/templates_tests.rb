Shindo.tests("Fog::AWS[:beanstalk] | templates", ['aws', 'beanstalk']) do

  pending if Fog.mocking?

  @beanstalk = Fog::AWS[:beanstalk]

  @application_name = uniq_id('fog-test-app')
  @template_name = uniq_id('fog-test-template')

  @template_description = 'A nice description'

  @application = @beanstalk.applications.create({:name => @application_name})

  params = {
      :application_name => @application_name,
      :name => @template_name,
      :description => @template_description,
      :solution_stack_name => '32bit Amazon Linux running Tomcat 7'
  }

  collection = @beanstalk.templates

  tests('success') do

    tests("#new(#{params.inspect})").succeeds do
      pending if Fog.mocking?
      collection.new(params)
    end

    tests("#create(#{params.inspect})").succeeds do
      pending if Fog.mocking?
      @instance = collection.create(params)
    end

    tests("#all").succeeds do
      pending if Fog.mocking?
      collection.all
    end

    tests("#get(#{@application_name}, #{@template_name})").succeeds do
      pending if Fog.mocking?
      collection.get(@application_name, @template_name)
    end

    if !Fog.mocking?
      @instance.destroy
    end
  end

  tests('failure') do

    tests("#get(#{@application_name}, #{@template_name})").returns(nil) do
      pending if Fog.mocking?
      collection.get(@application_name, @template_name)
    end

  end

  # delete application
  @application.destroy

end
