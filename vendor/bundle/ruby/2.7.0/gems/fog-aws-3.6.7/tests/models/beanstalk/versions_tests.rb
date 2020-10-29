Shindo.tests("Fog::AWS[:beanstalk] | versions", ['aws', 'beanstalk']) do

  pending if Fog.mocking?

  @beanstalk = Fog::AWS[:beanstalk]

  @application_name = uniq_id('fog-test-app')
  @version_name = uniq_id('fog-test-version')

  @version_description = 'A nice description'

  @application = @beanstalk.applications.create({:name => @application_name})

  params = {
      :application_name => @application_name,
      :label => @version_name,
      :description => @version_description
  }

  collection = @beanstalk.versions

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

    tests("#get(#{@application_name}, #{@version_name})").succeeds do
      pending if Fog.mocking?
      collection.get(@application_name, @version_name)
    end

    if !Fog.mocking?
      @instance.destroy
    end
  end

  tests('failure') do

    tests("#get(#{@application_name}, #{@version_name})").returns(nil) do
      pending if Fog.mocking?
      collection.get(@application_name, @version_name)
    end

  end

  # delete application
  @application.destroy
end
