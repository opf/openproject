require 'spec_helper'

describe ::Recaptcha::AdminController, type: :controller do
  let(:user) { FactoryBot.build_stubbed :admin }
  before do
    login_as user
  end

  describe 'as non admin' do
    let(:user) { FactoryBot.build_stubbed :user }

    it 'does not allow access' do
      get :show
      expect(response.status).to eq 403

      post :update
      expect(response.status).to eq 403
    end
  end

  describe 'show' do
    it 'renders show' do
      get :show
      expect(response).to be_successful
      expect(response).to render_template 'recaptcha/admin/show'
    end
  end

  describe '#update' do
    it 'fails if invalid param' do
      post :update, params: { recaptcha_type: :unknown }
      expect(response).to be_redirect
      expect(flash[:error]).to be_present
    end

    it 'succeeds' do
      expected = { recaptcha_type: 'v2', website_key: 'B', secret_key: 'A' }

      expect(Setting)
        .to receive(:plugin_openproject_recaptcha=)
        .with(expected)

      post :update, params: expected
      expect(response).to be_redirect
      expect(flash[:error]).to be_nil
      expect(flash[:notice]).to be_present
    end
  end
end
