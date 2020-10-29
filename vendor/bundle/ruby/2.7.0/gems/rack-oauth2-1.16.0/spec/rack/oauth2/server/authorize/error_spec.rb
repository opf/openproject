require 'spec_helper.rb'

describe Rack::OAuth2::Server::Authorize::BadRequest do
  let(:klass)        { Rack::OAuth2::Server::Authorize::BadRequest }
  let(:error)        { klass.new(:invalid_request) }
  let(:redirect_uri) { 'http://client.example.com/callback' }

  subject { error }
  it { should be_a Rack::OAuth2::Server::Abstract::BadRequest }
  its(:protocol_params) do
    should == {
      error:             :invalid_request,
      error_description: nil,
      error_uri:         nil,
      state:             nil
    }
  end

  describe '#finish' do
    context 'when redirect_uri is given' do
      before { error.redirect_uri = redirect_uri }

      context 'when protocol_params_location = :query' do
        before { error.protocol_params_location = :query }
        it 'should redirect with error in query' do
          state, header, response = error.finish
          state.should == 302
          header["Location"].should == "#{redirect_uri}?error=invalid_request"
        end
      end

      context 'when protocol_params_location = :fragment' do
        before { error.protocol_params_location = :fragment }
        it 'should redirect with error in fragment' do
          state, header, response = error.finish
          state.should == 302
          header["Location"].should == "#{redirect_uri}#error=invalid_request"
        end
      end

      context 'otherwise' do
        before { error.protocol_params_location = :other }
        it 'should redirect without error' do
          state, header, response = error.finish
          state.should == 302
          header["Location"].should == redirect_uri
        end
      end
    end

    context 'otherwise' do
      it 'should raise itself' do
        expect { error.finish }.to raise_error(klass) { |e|
          e.should == error
        }
      end
    end
  end
end

describe Rack::OAuth2::Server::Authorize::ErrorMethods do
  let(:klass)               { Rack::OAuth2::Server::Authorize::BadRequest }
  let(:redirect_uri)        { 'http://client.example.com/callback' }
  let(:default_description) { Rack::OAuth2::Server::Authorize::ErrorMethods::DEFAULT_DESCRIPTION }
  let(:env)                 { Rack::MockRequest.env_for("/authorize?client_id=client_id") }
  let(:request)             { Rack::OAuth2::Server::Authorize::Request.new env }
  let(:request_for_code)    { Rack::OAuth2::Server::Authorize::Code::Request.new env }
  let(:request_for_token)   { Rack::OAuth2::Server::Authorize::Token::Request.new env }

  describe 'bad_request!' do
    it do
      expect { request.bad_request! }.to raise_error klass
    end

    context 'when response_type = :code' do
      it 'should set protocol_params_location = :query' do
        expect { request_for_code.bad_request! }.to raise_error(klass) { |e|
          e.protocol_params_location.should == :query
        }
      end
    end

    context 'when response_type = :token' do
      it 'should set protocol_params_location = :fragment' do
        expect { request_for_token.bad_request! }.to raise_error(klass) { |e|
          e.protocol_params_location.should == :fragment
        }
      end
    end
  end

  Rack::OAuth2::Server::Authorize::ErrorMethods::DEFAULT_DESCRIPTION.keys.each do |error_code|
    method = "#{error_code}!"
    klass = case error_code
    when :server_error
      Rack::OAuth2::Server::Authorize::ServerError
    when :temporarily_unavailable
      Rack::OAuth2::Server::Authorize::TemporarilyUnavailable
    else
      Rack::OAuth2::Server::Authorize::BadRequest
    end
    describe method do
      it "should raise #{klass} with error = :#{error_code}" do
        klass =
        expect { request.send method }.to raise_error(klass) { |error|
          error.error.should       == error_code
          error.description.should == default_description[error_code]
        }
      end
    end
  end
end
