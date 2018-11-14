require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe ::OpenProject::TwoFactorAuthentication::TokenStrategy::Restdt, with_2fa_ee: true do
  describe 'sending messages' do
    let!(:user) { FactoryBot.create :user }
    let!(:device) { FactoryBot.create :two_factor_authentication_device_sms, user: user, channel: channel }

    let(:service_url) { 'https://example.org/foobar' }
    let(:params) {
      {
        service_url: service_url,
        username: 'foobar',
        password: 'password!'
      }
    }

    let(:base_request) {
      {
        user: 'foobar',
        pass: 'password!',
        rec: '0049123456789',
        lang: 'en',
        txt: '1234',
        output: 'plain'
      }
    }

    before do
      allow(OpenProject::Configuration)
        .to receive(:[]).with('2fa')
        .and_return(active_strategies: [:restdt], restdt: params)

      allow_any_instance_of(::OpenProject::TwoFactorAuthentication::TokenStrategy::Restdt)
        .to receive(:create_mobile_otp)
        .and_return('1234')
    end

    describe '#setup' do
      let(:channel) { :sms }
      let(:params) { { service_url: nil } }

      it 'raises an exception for incomplete params' do
        expect { described_class.validate! }
          .to raise_exception(ArgumentError)
      end
    end

    subject { ::TwoFactorAuthentication::TokenService.new user: user }
    let(:result) { subject.request }

    describe 'calling a mocked API', webmock: true do
      let(:response_code) { '200' }
      let(:channel) { :sms }

      before do
        stub_request(:post, service_url).to_return(status: 200, body: response_code)
      end

      shared_examples 'API response' do |success, errors|
        it 'calls the API' do
          expect(result.success).to eq success

          unless errors.nil?
            expect(result.errors.messages).to eq(base: errors)
          end

          expect(WebMock).to have_requested(:post, service_url).with { |request|
            requested_params = URI.decode_www_form(request.body).to_h.with_indifferent_access
            expect(requested_params).to include(base_request.merge(expected_params))
          }
        end
      end

      describe 'request body' do
        context 'with SMS' do
          let(:expected_params) { { onlycall: '0' } }
          it_behaves_like 'API response', true
        end

        context 'with voice' do
          let(:channel) { :voice }
          let(:expected_params) { { onlycall: '1' } }

          it_behaves_like 'API response', true
        end

        context 'with german locale' do
          let(:user) { FactoryBot.create(:user, language: 'de') }
          let(:expected_params) { { lang: 'de' } }

          it_behaves_like 'API response', true
        end
      end

      context 'when error' do
        let(:response_code) { '400' }
        let(:channel) { :sms }
        let(:expected_params) { { onlycall: '0' } }

        it_behaves_like 'API response',
                        false,
                        [I18n.t('two_factor_authentication.restdt.delivery_failed_with_code', code: 400)]
      end
    end
  end
end
