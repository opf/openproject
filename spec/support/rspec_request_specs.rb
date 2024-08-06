module RackTestHelper
  include Rack::Test::Methods

  def app
    Rails.application
  end
end

module CapybaraPage
  def page
    Capybara.string(response.body)
  end
end

RSpec.configure do |config|
  # Use Rack::Test for regular request specs (esp. API requests)
  config.include RackTestHelper, type: :request

  # If desired, we can use the Rails IntegrationTest request spec
  # (more like a feature spec) with this type.
  config.include RSpec::Rails::RequestExampleGroup, type: :rails_request
  config.include Capybara::RSpecMatchers, type: :rails_request
  config.include CapybaraPage, type: :rails_request
end
