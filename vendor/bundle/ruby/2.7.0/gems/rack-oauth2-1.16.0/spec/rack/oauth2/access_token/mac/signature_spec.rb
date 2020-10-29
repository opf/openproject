require 'spec_helper'

describe Rack::OAuth2::AccessToken::MAC::Signature do
  # From the example of Webtopay wallet API
  # ref) https://www.webtopay.com/wallet/
  context 'when ext is not given' do
    subject do
      Rack::OAuth2::AccessToken::MAC::Signature.new(
        secret:      'IrdTc8uQodU7PRpLzzLTW6wqZAO6tAMU',
        algorithm:   'hmac-sha-256',
        nonce:       'dj83hs9s',
        ts:          1336363200,
        method:      'GET',
        request_uri: '/wallet/rest/api/v1/payment/123',
        host:        'www.webtopay.com',
        port:        443
      )
    end
    its(:calculate) { should == 'OZE9fTk2qiRtL1jb01L8lRxC66PTiAGhMDEmboeVeLs=' }
  end

  # From the example of MAC spec section 1.1
  # ref) http://tools.ietf.org/pdf/draft-ietf-oauth-v2-http-mac-01.pdf
  context 'when ext is not given' do
    subject do
      Rack::OAuth2::AccessToken::MAC::Signature.new(
        secret:      '489dks293j39',
        algorithm:   'hmac-sha-1',
        nonce:       'dj83hs9s',
        ts:          1336363200,
        method:      'GET',
        request_uri: '/resource/1?b=1&a=2',
        host:        'example.com',
        port:        80
      )
    end
    its(:calculate) { should == '6T3zZzy2Emppni6bzL7kdRxUWL4=' }
  end

  # From the example of MAC spec section 3.2
  # ref) http://tools.ietf.org/pdf/draft-ietf-oauth-v2-http-mac-01.pdf
  context 'otherwise' do
    subject do
      Rack::OAuth2::AccessToken::MAC::Signature.new(
        secret:      '489dks293j39',
        algorithm:   'hmac-sha-1',
        nonce:       '7d8f3e4a',
        ts:          264095,
        method:      'POST',
        request_uri: '/request?b5=%3D%253D&a3=a&c%40=&a2=r%20b&c2&a3=2+q',
        host:        'example.com',
        port:        80,
        ext:         'a,b,c'
      )
    end
    its(:calculate) { should == '+txL5oOFHGYjrfdNYH5VEzROaBY=' }
  end

end
