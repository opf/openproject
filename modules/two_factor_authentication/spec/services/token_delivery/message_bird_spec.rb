require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'messagebird'

describe ::OpenProject::TwoFactorAuthentication::TokenStrategy::MessageBird, with_2fa_ee: true do
  describe 'sending messages' do
    let!(:user) { FactoryBot.create :user, language: locale }
    let!(:locale) { 'en' }
    let!(:device) { FactoryBot.create :two_factor_authentication_device_sms, user: user, channel: channel }

    let(:service_url) { 'https://example.org/foobar' }
    let(:params) {
      {
          apikey: 'whatever'
      }
    }

    before do
      allow(OpenProject::Configuration)
        .to receive(:[]).with('2fa')
        .and_return(active_strategies: [:message_bird], message_bird: params)

      allow_any_instance_of(::OpenProject::TwoFactorAuthentication::TokenStrategy::MessageBird)
        .to receive(:create_mobile_otp)
        .and_return('1234')
    end

    describe '#setup' do
      let(:channel) { :sms }
      let(:params) { { apikey: nil } }

      it 'raises an exception for incomplete params' do
        expect { described_class.validate! }
          .to raise_exception(ArgumentError)
      end
    end

    subject { ::TwoFactorAuthentication::TokenService.new user: user }
    let(:result) { subject.request }

    describe 'calling the test API' do
      let(:apikey) { ENV['MESSAGEBIRD_TEST_APIKEY'] }
      let(:params) { { apikey: apikey } }

      before do
        skip 'Missing MESSAGEBIRD_TEST_APIKEY environment variable' unless apikey.present?
      end

      context 'with SMS' do
        let(:channel) { :sms }

        it 'returns success in the service' do
          expect(result).to be_success
        end
      end

      context 'with VOICE' do
        let(:channel) { :voice }

        it 'returns success in the service' do
          expect(result).to be_success
        end
      end
    end

    describe 'calling a mocked API Client' do
      let(:messagebird) { double(::MessageBird::Client) }

      let(:failed_count) { 0 }
      let(:response) { instance_double(::MessageBird::Message, recipients: { 'totalDeliveryFailedCount' => failed_count }) }
      let(:channel) { :sms }

      before do
        allow_any_instance_of(::OpenProject::TwoFactorAuthentication::TokenStrategy::MessageBird)
          .to receive(:message_bird_client)
          .and_return(messagebird)
      end

      context 'with SMS' do
        before do
          expect(messagebird)
            .to receive(:message_create)
            .with(Setting.app_title,
                  '49123456789',
                  I18n.t('two_factor_authentication.text_otp_delivery_message_sms', app_title: Setting.app_title, token: '1234'),
                  validity: 720)
            .and_return(response)
        end

        it 'returns success in the service' do
          expect(result).to be_success
        end

        context 'failure' do
          let(:failed_count) { 1 }

          it 'returns error in the service' do
            expect(result).not_to be_success
            expect(result.errors).to be_present
          end
        end
      end

      context 'with voice' do
        let(:channel) { :voice }
        let(:expected_language) { :'en-us' }

        before do
          expect(messagebird)
            .to receive(:voice_message_create)
            .with('49123456789',
                  subject.strategy.send(:localized_message, locale, '1234'),
                  ifMachine: :continue,
                  language: expected_language)
            .and_return(response)
        end

        it 'returns success in the service' do
          expect(result).to be_success
        end

        context 'failure' do
          let(:failed_count) { 1 }

          it 'returns error in the service' do
            expect(result).not_to be_success
            expect(result.errors).to be_present
          end
        end

        context 'with german locale' do
          let(:locale) { 'de' }
          let(:expected_language) { :'de-de' }

          it 'returns success in the service' do
            expect(subject.strategy).to receive(:has_localized_text?).with('de').and_return true
            expect(result).to be_success
          end
        end
      end
    end
  end
end
