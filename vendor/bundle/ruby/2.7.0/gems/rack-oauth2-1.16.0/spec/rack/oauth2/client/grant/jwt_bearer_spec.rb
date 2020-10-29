require 'spec_helper.rb'

describe Rack::OAuth2::Client::Grant::JWTBearer do
  let(:grant) { Rack::OAuth2::Client::Grant::JWTBearer }

  context 'when JWT assertion is given' do
    let :attributes do
      {assertion: 'header.payload.signature'}
    end
    subject { grant.new attributes }
    its(:as_json) do
      should == {grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: 'header.payload.signature'}
    end
  end

  context 'otherwise' do
    it do
      expect { grant.new }.to raise_error AttrRequired::AttrMissing
    end
  end
end
