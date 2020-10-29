require 'spec_helper.rb'

describe Rack::OAuth2::Client::Grant::SAML2Bearer do
  let(:grant) { Rack::OAuth2::Client::Grant::SAML2Bearer }

  context 'when JWT assertion is given' do
    let :attributes do
      {assertion: '<xml>...</xml>'}
    end
    subject { grant.new attributes }
    its(:as_json) do
      should == {grant_type: 'urn:ietf:params:oauth:grant-type:saml2-bearer', assertion: '<xml>...</xml>'}
    end
  end

  context 'otherwise' do
    it do
      expect { grant.new }.to raise_error AttrRequired::AttrMissing
    end
  end
end
