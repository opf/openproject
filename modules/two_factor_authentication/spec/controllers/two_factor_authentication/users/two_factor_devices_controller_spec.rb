require_relative '../../../spec_helper'
require_relative '../authentication_controller_shared_examples'

RSpec.describe TwoFactorAuthentication::Users::TwoFactorDevicesController do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, login: 'foobar') }
  let(:other_user) { create(:user) }
  let(:logged_in_user) { admin }
  let(:active_strategies) { [:developer] }
  let(:config) { {} }

  include_context 'with settings' do
    let(:settings) do
      {
        plugin_openproject_two_factor_authentication: {
          'active_strategies' => active_strategies
        }.merge(config)
      }
    end
  end

  before do
    allow(User).to receive(:current).and_return(logged_in_user)
    allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager)
      .to receive(:add_default_strategy?)
            .and_return false
  end

  describe 'accessing' do
    before do
      get :new, params: { id: user.id, type: :sms }
    end

    context 'when the same user' do
      let(:logged_in_user) { other_user }

      it 'does not give access' do
        expect(response.status).to eq 403
      end
    end

    context 'when not the same user' do
      let(:logged_in_user) { user }

      it 'does not give access' do
        expect(response.status).to eq 403
      end
    end

    context 'when not the same user and admin' do
      let(:logged_in_user) { admin }

      it 'renders the page' do
        expect(response).to be_successful
        expect(response).to render_template 'new'
      end

      context 'when no active strategies' do
        let(:active_strategies) { [] }

        it 'renders a 404 because no strategies enabled' do
          expect(response.status).to eq 404
        end
      end
    end
  end

  describe 'with active strategy' do
    let(:active_strategies) { [:developer] }

    describe '#new' do
      context 'without type' do
        before do
          get :new, params: { id: user.id }
        end

        it 'shows an error' do
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'with unsupported type' do
        before do
          get :new, params: { id: user.id, type: :totp }
        end

        it 'shows an error' do
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'with type' do
        before do
          get :new, params: { id: user.id, type: :sms }
        end

        it 'renders the new form' do
          expect(response).to be_successful
          expect(response).to render_template 'new'
        end
      end
    end

    describe '#register' do
      context 'with missing phone' do
        let(:params) { { identifier: 'foo' } }

        it 'renders action new' do
          post :register, params: { id: user.id, key: :sms, device: params }

          expect(response).to be_successful
          expect(response).to render_template 'new'
          expect(assigns[:device]).to be_invalid
        end
      end

      context 'with valid params' do
        let(:params) { { phone_number: '+49123456789', identifier: 'foo' } }

        it 'redirects to result' do
          post :register, params: { id: user.id, key: :sms, device: params }

          device = user.otp_devices.reload.last
          expect(response).to redirect_to edit_user_path(user.id, tab: :two_factor_authentication)

          expect(device.identifier).to eq 'foo (+49123456789)'
          expect(device.phone_number).to eq '+49123456789'
          expect(device.default).to be_truthy
          expect(device.active).to be_truthy
        end

        context 'when user has active sessions' do
          let!(:plain_session1) { create(:user_session, user:) }
          let!(:user_session1) { Sessions::UserSession.find_by(session_id: plain_session1.session_id) }

          let!(:plain_session2) { create(:user_session, user:) }
          let!(:user_session2) { Sessions::UserSession.find_by(session_id: plain_session2.session_id) }

          let!(:other_plain_session) { create(:user_session, user: other_user) }
          let!(:other_session) { Sessions::UserSession.find_by(session_id: other_plain_session.session_id) }

          it 'drops all sessions of that user' do
            post :register, params: { id: user.id, key: :sms, device: params }

            expect { user_session1.reload }.to raise_error(ActiveRecord::RecordNotFound)
            expect { user_session2.reload }.to raise_error(ActiveRecord::RecordNotFound)

            expect { other_session.reload }.not_to raise_error
          end

          context 'when user has an active device' do
            let!(:device) { create(:two_factor_authentication_device_totp, user:, default: true) }

            it 'does nothing' do
              post :register, params: { id: user.id, key: :sms, device: params }

              expect(user.otp_devices.count).to eq 2
              expect(device.reload).to be_default
              expect(user.otp_devices.last).to be_active
              expect(user.otp_devices.last).not_to be_default

              expect { user_session1.reload }.not_to raise_error
              expect { user_session2.reload }.not_to raise_error

              expect { other_session.reload }.not_to raise_error
            end
          end
        end
      end
    end

    describe '#confirm' do
      it 'fails on GET' do
        expect { get :confirm }.to raise_error(ActionController::UrlGenerationError)
      end

      it 'fails on POST' do
        expect { post :confirm }.to raise_error(ActionController::UrlGenerationError)
      end
    end

    describe '#destroy' do
      it 'croaks on missing id' do
        delete :destroy, params: { id: user.id, device_id: '1234' }
        expect(response.status).to eq 404
      end

      context 'with existing non-default device' do
        let!(:device) { create(:two_factor_authentication_device_totp, user:, default: false) }

        it 'deletes it' do
          delete :destroy, params: { id: user.id, device_id: device.id }
          expect(response).to redirect_to edit_user_path(user, tab: :two_factor_authentication)
          expect(user.otp_devices.reload).to eq []
        end
      end

      context 'with existing default device' do
        let!(:device) { create(:two_factor_authentication_device_totp, user:, default: true) }

        it 'deletes it' do
          delete :destroy, params: { id: user.id, device_id: device.id }
          expect(response).to redirect_to edit_user_path(user, tab: :two_factor_authentication)
          expect(user.otp_devices.reload).to eq []
        end
      end

      context 'with existing default device AND enforced' do
        let!(:device) { create(:two_factor_authentication_device_totp, user:, default: true) }
        let(:config) { { enforced: true } }

        it 'cannot be deleted' do
          delete :destroy, params: { id: user.id, device_id: device.id }
          expect(user.otp_devices.reload).to eq [device]
        end
      end
    end
  end
end
