require 'spec_helper.rb'

describe Rack::OAuth2::Client::Grant::RefreshToken do
  let(:grant) { Rack::OAuth2::Client::Grant::RefreshToken }

  context 'when refresh_token is given' do
    let :attributes do
      {refresh_token: 'refresh_token'}
    end
    subject { grant.new attributes }
    its(:as_json) do
      should == {grant_type: :refresh_token, refresh_token: 'refresh_token'}
    end
  end

  context 'otherwise' do
    it do
      expect { grant.new }.to raise_error AttrRequired::AttrMissing
    end
  end
end
