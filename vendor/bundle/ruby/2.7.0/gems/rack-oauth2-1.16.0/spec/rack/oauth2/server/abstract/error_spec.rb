require 'spec_helper.rb'

describe Rack::OAuth2::Server::Abstract::Error do

  context 'when full attributes are given' do
    subject do
      Rack::OAuth2::Server::Abstract::Error.new 400, :invalid_request, 'Missing some required params', uri: 'http://server.example.com/error'
    end
    its(:status)      { should == 400 }
    its(:error)       { should == :invalid_request }
    its(:description) { should == 'Missing some required params' }
    its(:uri)         { should == 'http://server.example.com/error' }
    its(:protocol_params) do
      should == {
        error:             :invalid_request,
        error_description: 'Missing some required params',
        error_uri:         'http://server.example.com/error'
      }
    end
  end

  context 'when optional attributes are not given' do
    subject do
      Rack::OAuth2::Server::Abstract::Error.new 400, :invalid_request
    end
    its(:status)      { should == 400 }
    its(:error)       { should == :invalid_request }
    its(:description) { should be_nil }
    its(:uri)         { should be_nil }
    its(:protocol_params) do
      should == {
        error:             :invalid_request,
        error_description: nil,
        error_uri:         nil
      }
    end
  end

end

describe Rack::OAuth2::Server::Abstract::BadRequest do
  its(:status) { should == 400 }
end

describe Rack::OAuth2::Server::Abstract::Unauthorized do
  its(:status) { should == 401 }
end

describe Rack::OAuth2::Server::Abstract::Forbidden do
  its(:status) { should == 403 }
end

describe Rack::OAuth2::Server::Abstract::ServerError do
  its(:status) { should == 500 }
end

describe Rack::OAuth2::Server::Abstract::TemporarilyUnavailable do
  its(:status) { should == 503 }
end
