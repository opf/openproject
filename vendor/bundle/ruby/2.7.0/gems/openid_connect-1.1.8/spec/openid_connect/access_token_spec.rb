require 'spec_helper'

describe OpenIDConnect::AccessToken do
  subject { access_token }
  let :client do
    OpenIDConnect::Client.new(
      identifier:'client_id',
      host: 'server.example.com'
    )
  end
  let :access_token do
    OpenIDConnect::AccessToken.new(
      access_token: 'access_token',
      client: client
    )
  end

  its(:token_type) { should == :bearer }
  its(:optional_attributes) { should include :id_token }

  context 'when id_token is given' do
    subject { access_token }
    let :access_token do
      OpenIDConnect::AccessToken.new(
        access_token: 'access_token',
        id_token: id_token,
        client: client
      )
    end

    context 'when IdToken object' do
      let :id_token do
        OpenIDConnect::ResponseObject::IdToken.new(
          iss: 'https://server.example.com',
          sub: 'user_id',
          aud: 'client_id',
          nonce: 'nonce',
          exp: 1.week.from_now,
          iat: Time.now
        )
      end
      its(:id_token) { should be_a OpenIDConnect::ResponseObject::IdToken }
      its(:token_response) { should_not include :id_token }
    end

    context 'when JWT string' do
      let(:id_token) { 'id_token' }
      its(:id_token) { should == 'id_token' }
      its(:token_response) { should_not include :id_token }
    end
  end

  shared_examples_for :access_token_error_handling do
    context 'when bad_request' do
      it 'should raise OpenIDConnect::Forbidden' do
        mock_json :get, endpoint, 'errors/invalid_request', :HTTP_AUTHORIZATION => 'Bearer access_token', status: 400 do
          expect { request }.to raise_error OpenIDConnect::BadRequest
        end
      end
    end

    context 'when unauthorized' do
      it 'should raise OpenIDConnect::Unauthorized' do
        mock_json :get, endpoint, 'errors/invalid_access_token', :HTTP_AUTHORIZATION => 'Bearer access_token', status: 401 do
          expect { request }.to raise_error OpenIDConnect::Unauthorized
        end
      end
    end

    context 'when forbidden' do
      it 'should raise OpenIDConnect::Forbidden' do
        mock_json :get, endpoint, 'errors/insufficient_scope', :HTTP_AUTHORIZATION => 'Bearer access_token', status: 403 do
          expect { request }.to raise_error OpenIDConnect::Forbidden
        end
      end
    end

    context 'when unknown' do
      it 'should raise OpenIDConnect::HttpError' do
        mock_json :get, endpoint, 'errors/unknown', :HTTP_AUTHORIZATION => 'Bearer access_token', status: 500 do
          expect { request }.to raise_error OpenIDConnect::HttpError
        end
      end
    end
  end

  describe '#userinfo!' do
    it do
      userinfo = mock_json :get, client.userinfo_uri, 'userinfo/openid', :HTTP_AUTHORIZATION => 'Bearer access_token' do
        access_token.userinfo!
      end
      userinfo.should be_instance_of OpenIDConnect::ResponseObject::UserInfo
    end

    describe 'error handling' do
      let(:endpoint) { client.userinfo_uri }
      let(:request) { access_token.userinfo! }
      it_behaves_like :access_token_error_handling
    end
  end
end