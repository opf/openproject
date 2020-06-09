require 'request_headers'

module CapybaraHeaderHelpers
  shared_context 'in Revit' do
    before(:each) { add_headers('User-Agent' => 'foo bar Revit') }
  end

  def add_headers(custom_headers)
    if Capybara.current_driver == :rack_test
      custom_headers.each do |name, value|
        page.driver.browser.header(name, value)
      end
    else
      CustomHeadersHelper.headers = custom_headers
    end
  end
end