require 'spec_helper'

describe Rack::OAuth2::AccessToken::MAC::Verifier do
  let(:verifier) { Rack::OAuth2::AccessToken::MAC::Verifier.new(algorithm: algorithm) }
  subject { verifier }

  context 'when "hmac-sha-1" is specified' do
    let(:algorithm) { 'hmac-sha-1' }
    its(:hash_generator) { should be_instance_of OpenSSL::Digest::SHA1 }
  end

  context 'when "hmac-sha-256" is specified' do
    let(:algorithm) { 'hmac-sha-256' }
    its(:hash_generator) { should be_instance_of OpenSSL::Digest::SHA256 }
  end

  context 'otherwise' do
    let(:algorithm) { 'invalid' }
    it do
      expect { verifier.send(:hash_generator) }.to raise_error(StandardError, 'Unsupported Algorithm')
    end
  end


end
