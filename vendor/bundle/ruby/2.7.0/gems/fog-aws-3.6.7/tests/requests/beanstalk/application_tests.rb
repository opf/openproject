Shindo.tests('AWS::ElasticBeanstalk | application_tests', ['aws', 'beanstalk']) do

  def unique_name(prefix)
    #get time (with 1/100th of sec accuracy)
    #want unique domain name and if provider is fast, this can be called more than once per second
    time = Time.now.to_i.to_s
    prefix + time
  end

  unless Fog.mocking?
    @beanstalk = Fog::AWS[:beanstalk]
  end

  @test_description = "A unique description."

  @test_app_name = unique_name("fog-test-app-")

  tests('success') do
    pending if Fog.mocking?

    @describe_applications_format = {
        'DescribeApplicationsResult' => {
            'Applications' => [
                'ApplicationName' => String,
                'ConfigurationTemplates' => [String],
                'Description' => Fog::Nullable::String,
                'DateCreated' => Time,
                'DateUpdated' => Time,
                'Versions' => [String]
            ]},
        'ResponseMetadata' => {'RequestId'=> String},
    }

    tests("#describe_applications format").formats(@describe_applications_format) do
      result = @beanstalk.describe_applications.body
    end

    test("#create_application") {
      response = @beanstalk.create_application({
                                                   'ApplicationName' => @test_app_name,
                                                   'Description' => @test_description
                                               })

      result = false
      if response.status == 200

        app_info = response.body['CreateApplicationResult']['Application']
        if app_info
          if app_info['ApplicationName'] == @test_app_name &&
              app_info['Description'] == @test_description &&
              app_info['ConfigurationTemplates'].empty? &&
              app_info['Versions'].empty?
            result = true
          end
        end
      end

      result
    }

    test("#describe_applications all") {
      response = @beanstalk.describe_applications

      result = false
      if response.status == 200
        apps = response.body['DescribeApplicationsResult']['Applications']
        apps.each { |app_info|
          if app_info
            if app_info['ApplicationName'] == @test_app_name &&
                app_info['Description'] == @test_description &&
                app_info['ConfigurationTemplates'].empty? &&
                app_info['Versions'].empty?
              result = true
            end
          end
        }
      end

      result
    }

    test("#create_application filter") {
      # Test for a specific app
      response = @beanstalk.describe_applications([@test_app_name])

      result = false
      if response.status == 200
        apps = response.body['DescribeApplicationsResult']['Applications']
        if apps && apps.length == 1
          app_info = apps.first
          if app_info['ApplicationName'] == @test_app_name &&
              app_info['Description'] == @test_description &&
              app_info['ConfigurationTemplates'].empty? &&
              app_info['Versions'].empty?
            result = true
          end
        end
      end

      result
    }

    test("#update_application description") {

      @test_description = "A completely new description."

      response = @beanstalk.update_application({
                                                   'ApplicationName' => @test_app_name,
                                                   'Description' => @test_description
                                               })

      result = false
      if response.status == 200
        app_info = response.body['UpdateApplicationResult']['Application']
        if app_info
          if app_info['ApplicationName'] == @test_app_name &&
              app_info['Description'] == @test_description &&
              app_info['ConfigurationTemplates'].empty? &&
              app_info['Versions'].empty?
            result = true
          end
        end
      end

      result
    }

    test("#delete_application") {
      response = @beanstalk.delete_application(@test_app_name)

      result = false
      if response.status == 200
          result = true
      end

      result
    }

  end
end
