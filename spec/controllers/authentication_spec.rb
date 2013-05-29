require File.expand_path('../../spec_helper', __FILE__)

describe TimelinesAuthenticationController do
  describe 'index.html' do
    def fetch
      get 'index'
    end

    it_should_behave_like "a controller action with require_login"
  end

  describe 'index.xml' do
    def fetch
      get 'index', :format => 'xml'
    end

    it_should_behave_like "a controller action with require_login"
  end
end
