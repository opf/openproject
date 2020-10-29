require 'spec_helper.rb'

describe Rack::OAuth2::Client::Grant::ClientCredentials do
  its(:as_json) do
    should == {grant_type: :client_credentials}
  end
end
