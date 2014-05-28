require 'spec_helper'
require 'rack/test'

describe API do
  include Rack::Test::Methods

  describe "GET /api/v3" do
    it "should be success" do
      get "/api/v3"
      response.status.should == 200
    end
  end
end
