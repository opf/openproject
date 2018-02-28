require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'messagebird'

describe ::OpenProject::TwoFactorAuthentication::TokenStrategy::MessageBird, with_2fa_ee: true do
  let(:channel) { :sms }
  let(:locale) { 'en' }
  let(:user) { FactoryGirl.create :user, language: locale }
  let(:device) { FactoryGirl.create :two_factor_authentication_device_sms, user: user, channel: channel }
  let(:strategy) { described_class.new user: user, device: device, channel: channel }

  before do
    allow(strategy).to receive(:token).and_return '1234'
  end

  describe '#build_recipients' do
    subject do
      {}.tap do |params|
        strategy.send(:build_recipients, params)
      end[:recipients]
    end

    it 'strips all spaces and country lead' do
      expect(subject).to eq '49123456789'
    end
  end

  describe '#build_localized_message' do
    subject do
      {}.tap do |params|
        strategy.send(:build_localized_message, params)
      end
    end

    context 'en' do
      let(:locale) { 'en' }

      it 'returns the correct language and message' do
        expect(subject[:language]).to eq :'en-us'
        expect(subject[:message]).to include 'Your OpenProject one-time password is 1234'
      end
    end

    context 'de' do
      let(:locale) { 'de' }

      it 'returns the correct language and message' do
        expect(I18n).to receive(:t)
          .twice
          .with('two_factor_authentication.text_otp_delivery_message_sms',
                hash_including(locale: 'de'))
          .and_return 'localized string'

        expect(subject[:language]).to eq :'de-de'
        expect(subject[:message]).to eq 'localized string'
      end
    end

    context 'unsupported locale' do
      before do
        allow(user).to receive(:language).and_return 'unsupported'
        # Allow I18n to receive unsupported language
        allow(I18n).to receive(:enforce_available_locales!).and_call_original
        allow(I18n).to receive(:enforce_available_locales!).with('unsupported')
      end

      it 'falls back to english' do
        expect(subject[:language]).to eq :'en-us'
      end
    end
  end
end
