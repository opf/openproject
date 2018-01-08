require_relative '../../../spec_helper'
require_relative './../authentication_controller_shared_examples'

describe ::TwoFactorAuthentication::Users::TwoFactorDevicesController, with_2fa_ee: true do
  let(:admin) { FactoryGirl.create :admin }
  let(:user) { FactoryGirl.create(:user, login: 'foobar') }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:logged_in_user) { admin }
  let(:active_strategies) { [:developer] }
  let(:config) { {} }

  before do
    allow(User).to receive(:current).and_return(logged_in_user)
    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration)
      .to receive(:[]).with('2fa')
      .and_return({ active_strategies: active_strategies }.merge(config).with_indifferent_access)
  end

  describe 'accessing' do
    before do
      get :new, params: { id: user.id }
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
        expect(response).to be_success
        expect(response).to render_template 'new_type'
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

        it 'renders the new form' do
          expect(response).to be_success
          expect(response).to render_template 'new_type'
        end
      end

      context 'with type' do
        before do
          get :new, params: { id: user.id, type: :sms }
        end

        it 'renders the new form' do
          expect(response).to be_success
          expect(response).to render_template 'new'
        end
      end
    end

    describe '#register' do
      before do
        post :register, params: { id: user.id, key: :sms, device: params }
      end

      context 'with missing phone' do
        let(:params) { { identifier: 'foo' } }

        it 'renders action new' do
          expect(response).to be_success
          expect(response).to render_template 'new'
          expect(assigns[:device]).to be_invalid
        end
      end

      context 'with valid params' do
        let(:params) { { phone_number: '+49123456789', identifier: 'foo' } }

        it 'redirects to result' do
          device = user.otp_devices.reload.last
          expect(response).to redirect_to edit_user_path(user.id, tab: :two_factor_authentication)

          expect(device.identifier).to eq 'foo (+49123456789)'
          expect(device.phone_number).to eq '+49123456789'
          expect(device.default).to be_truthy
          expect(device.active).to be_truthy
        end
      end
    end

    describe '#destroy' do
      it 'croaks on missing id' do
        delete :destroy, params: { id: user.id, device_id: '1234' }
        expect(response.status).to eq 404
      end

      context 'with existing non-default device' do
        let!(:device) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, default: false}

        it 'deletes it' do
          delete :destroy, params: { id: user.id, device_id: device.id }
          expect(response).to redirect_to edit_user_path(user, tab: :two_factor_authentication)
          expect(user.otp_devices.reload).to eq []
        end
      end

      context 'with existing default device' do
        let!(:device) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, default: true}

        it 'deletes it' do
          delete :destroy, params: { id: user.id, device_id: device.id }
          expect(response).to redirect_to edit_user_path(user, tab: :two_factor_authentication)
          expect(user.otp_devices.reload).to eq []
        end
      end

      context 'with existing default device AND enforced' do
        let!(:device) { FactoryGirl.create :two_factor_authentication_device_totp, user: user, default: true}
        let(:config) { { enforced: true } }

        it 'cannot be deleted' do
          delete :destroy, params: { id: user.id, device_id: device.id }
          expect(user.otp_devices.reload).to eq [device]
        end
      end
    end
  end
end
