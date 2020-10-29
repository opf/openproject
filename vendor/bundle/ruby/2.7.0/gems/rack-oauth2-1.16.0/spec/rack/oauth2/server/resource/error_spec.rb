require 'spec_helper.rb'

describe Rack::OAuth2::Server::Resource::BadRequest do
  let(:error) { Rack::OAuth2::Server::Resource::BadRequest.new(:invalid_request) }

  it { should be_a Rack::OAuth2::Server::Abstract::BadRequest }

  describe '#finish' do
    it 'should respond in JSON' do
      status, header, response = error.finish
      status.should == 400
      header['Content-Type'].should == 'application/json'
      response.should == ['{"error":"invalid_request"}']
    end
  end
end

describe Rack::OAuth2::Server::Resource::Unauthorized do
  let(:error) { Rack::OAuth2::Server::Resource::Unauthorized.new(:invalid_token) }
  let(:realm) { Rack::OAuth2::Server::Resource::DEFAULT_REALM }

  it { should be_a Rack::OAuth2::Server::Abstract::Unauthorized }

  describe '#scheme' do
    it do
      expect { error.scheme }.to raise_error(RuntimeError, 'Define me!')
    end
  end

  context 'when scheme is defined' do
    let :error_with_scheme do
      e = error
      e.instance_eval do
        def scheme
          :Scheme
        end
      end
      e
    end

    describe '#finish' do
      it 'should respond in JSON' do
        status, header, response = error_with_scheme.finish
        status.should == 401
        header['Content-Type'].should == 'application/json'
        header['WWW-Authenticate'].should == "Scheme realm=\"#{realm}\", error=\"invalid_token\""
        response.should == ['{"error":"invalid_token"}']
      end

      context 'when error_code is not invalid_token' do
        let(:error) { Rack::OAuth2::Server::Resource::Unauthorized.new(:something) }

        it 'should have error_code in body but not in WWW-Authenticate header' do
          status, header, response = error_with_scheme.finish
          header['WWW-Authenticate'].should == "Scheme realm=\"#{realm}\""
          response.first.should include '"error":"something"'
        end
      end

      context 'when no error_code is given' do
        let(:error) { Rack::OAuth2::Server::Resource::Unauthorized.new }

        it 'should have error_code in body but not in WWW-Authenticate header' do
          status, header, response = error_with_scheme.finish
          header['WWW-Authenticate'].should == "Scheme realm=\"#{realm}\""
          response.first.should == '{"error":"unauthorized"}'
        end
      end

      context 'when realm is specified' do
        let(:realm) { 'server.example.com' }
        let(:error) { Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(:something, nil, realm: realm) }

        it 'should use given realm' do
          status, header, response = error_with_scheme.finish
          header['WWW-Authenticate'].should == "Scheme realm=\"#{realm}\""
          response.first.should include '"error":"something"'
        end
      end
    end
  end
end

describe Rack::OAuth2::Server::Resource::Forbidden do
  let(:error) { Rack::OAuth2::Server::Resource::Forbidden.new(:insufficient_scope) }

  it { should be_a Rack::OAuth2::Server::Abstract::Forbidden }

  describe '#finish' do
    it 'should respond in JSON' do
      status, header, response = error.finish
      status.should == 403
      header['Content-Type'].should == 'application/json'
      response.should == ['{"error":"insufficient_scope"}']
    end
  end

  context 'when scope option is given' do
    let(:error) { Rack::OAuth2::Server::Resource::Bearer::Forbidden.new(:insufficient_scope, 'Desc', scope: [:scope1, :scope2]) }

    it 'should have blank WWW-Authenticate header' do
      status, header, response = error.finish
      response.first.should include '"scope":"scope1 scope2"'
    end
  end
end

describe Rack::OAuth2::Server::Resource::Bearer::ErrorMethods do
  let(:bad_request)         { Rack::OAuth2::Server::Resource::BadRequest }
  let(:forbidden)           { Rack::OAuth2::Server::Resource::Forbidden }
  let(:redirect_uri)        { 'http://client.example.com/callback' }
  let(:default_description) { Rack::OAuth2::Server::Resource::ErrorMethods::DEFAULT_DESCRIPTION }
  let(:env)                 { Rack::MockRequest.env_for("/authorize?client_id=client_id") }
  let(:request)             { Rack::OAuth2::Server::Resource::Request.new env }

  describe 'bad_request!' do
    it do
      expect { request.bad_request! :invalid_request }.to raise_error bad_request
    end
  end

  describe 'unauthorized!' do
    it do
      expect { request.unauthorized! :invalid_client }.to raise_error(RuntimeError, 'Define me!')
    end
  end

  Rack::OAuth2::Server::Resource::ErrorMethods::DEFAULT_DESCRIPTION.keys.each do |error_code|
    method = "#{error_code}!"
    case error_code
    when :invalid_request
      describe method do
        it "should raise Rack::OAuth2::Server::Resource::BadRequest with error = :#{error_code}" do
          expect { request.send method }.to raise_error(bad_request) { |error|
            error.error.should       == error_code
            error.description.should == default_description[error_code]
          }
        end
      end
    when :insufficient_scope
      describe method do
        it "should raise Rack::OAuth2::Server::Resource::Forbidden with error = :#{error_code}" do
          expect { request.send method }.to raise_error(forbidden) { |error|
            error.error.should       == error_code
            error.description.should == default_description[error_code]
          }
        end
      end
    else
      describe method do
        it do
          expect { request.send method }.to raise_error(RuntimeError, 'Define me!')
        end
      end
    end
  end
end
