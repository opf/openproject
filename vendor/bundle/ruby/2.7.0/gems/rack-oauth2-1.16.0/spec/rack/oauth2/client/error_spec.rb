require 'spec_helper.rb'

describe Rack::OAuth2::Client::Error do
  let :error do
    {
      error: :invalid_request,
      error_description: 'Include invalid parameters',
      error_uri: 'http://server.example.com/error/invalid_request'
    }
  end
  subject do
    Rack::OAuth2::Client::Error.new 400, error
  end

  its(:status)   { should == 400 }
  its(:message)  { should == [error[:error], error[:error_description]].join(' :: ') }
  its(:response) { should == error }
end
