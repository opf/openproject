require 'spec_helper'

describe API do
  describe "GET /api/v3" do
    it "should be success" do
      get "/api/v3"
      response.status.should == 200
    end
  end
end
