require 'spec_helper'

describe Rack::OAuth2::AccessToken::MAC::Sha256HexVerifier do

  # From the example of webtopay wallet API spec
  # ref) https://www.webtopay.com/wallet/#authentication
  context 'when example from webtopay wallet API' do
    subject do
      Rack::OAuth2::AccessToken::MAC::Sha256HexVerifier.new(
        algorithm: 'hmac-sha-256',
        raw_body: 'grant_type=authorization_code&code=SplxlOBeZQQYbYS6WxSbIA&redirect_uri=http%3A%2F%2Flocalhost%2Fabc'
      )
    end
    its(:calculate) { should == '21fb73c40b589622d0c78e9cd8900f89d9472aa724d0e5c3eca9ac1cd9d2a6d5' }
  end


  context 'when raw_body is empty' do
    subject do
      Rack::OAuth2::AccessToken::MAC::Sha256HexVerifier.new(
        algorithm: 'hmac-sha-256',
        raw_body: ''
      )
    end
    its(:calculate) { should be_nil }
  end

end
