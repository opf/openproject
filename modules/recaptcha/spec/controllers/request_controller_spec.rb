require 'spec_helper'

describe ::Recaptcha::RequestController, type: :controller do
  let(:user) { FactoryBot.create :user }
  before do
    login_as user
    allow(Setting)
      .to receive(:plugin_openproject_recaptcha)
      .and_return(recaptcha_type: 'v2', website_key: 'A', secret_key: 'B')

    session[:authenticated_user_id] = user.id
    session[:stage_secrets] = { recaptcha: 'asdf' }
  end

  describe 'request' do
    it 'renders the template' do
      get :perform
      expect(response).to be_successful
      expect(response).to render_template 'recaptcha/request/perform'
    end

    it 'skips if user is verified' do
      allow(::Recaptcha::Entry)
        .to receive_message_chain(:where, :exists?)
        .and_return true

      get :perform
      expect(response).to redirect_to stage_success_path(stage: :recaptcha, secret: 'asdf')
    end

    context 'if the user is an admin' do
      let(:user) { FactoryBot.create :admin }

      it 'skips the verification' do
        expect(controller).not_to receive(:perform)

        get :perform
        expect(response).to redirect_to stage_success_path(stage: :recaptcha, secret: 'asdf')
      end
    end
  end

  describe 'verify' do
    it 'succeeds assuming verification works' do
      allow(@controller).to receive(:valid_recaptcha?).and_return true
      expect(@controller).to receive(:save_recpatcha_verification_success!)
      post :verify
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to stage_success_path(stage: :recaptcha, secret: 'asdf')
    end

    it 'fails assuming verification fails' do
      allow(@controller).to receive(:valid_recaptcha?).and_return false
      post :verify
      expect(flash[:error]).to be_present
      expect(response).to redirect_to stage_failure_path(stage: :recaptcha)
    end
  end
end
