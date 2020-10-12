require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../shared_examples')

describe ::Avatars::MyAvatarController, type: :controller do
  include_context "there are users with and without avatars"
  let(:user) { user_without_avatar }
  let(:enabled) { true }

  before do
    login_as user
    allow(::OpenProject::Avatars::AvatarManager).to receive(:avatars_enabled?).and_return enabled
  end

  describe '#show' do
    before do
      get :show
    end

    it 'renders the edit action' do
      expect(response).to be_successful
      expect(response).to render_template 'avatars/my/avatar'
    end
  end

  describe '#update' do
    context 'when not logged in' do
      let(:user) { User.anonymous }

      it 'renders 403' do
        post :update
        expect(response).to redirect_to signin_path(back_url: edit_my_avatar_url)
      end
    end

    context 'when not enabled' do
      let(:enabled) { false }

      it 'renders 404' do
        post :update
        expect(response.status).to eq 404
      end
    end

    it 'returns invalid method for post request' do
      post :update
      expect(response).not_to be_successful
      expect(response.status).to eq 405
    end

    it 'calls the service for put' do
      expect_any_instance_of(::Avatars::UpdateService)
        .to receive(:replace)
        .and_return(ServiceResult.new(success: true))

      put :update
      expect(response).to be_successful
      expect(response.status).to eq 200
    end

    it 'calls the service for put' do
      expect_any_instance_of(::Avatars::UpdateService)
        .to receive(:replace)
        .and_return(ServiceResult.new(success: false))

      put :update
      expect(response).not_to be_successful
      expect(response.status).to eq 400
    end
  end

  describe '#delete' do
    it 'returns invalid method for post request' do
      post :destroy
      expect(response).not_to be_successful
      expect(response.status).to eq 405
    end

    it 'calls the service for delete' do
      expect_any_instance_of(::Avatars::UpdateService)
        .to receive(:destroy)
        .and_return(ServiceResult.new(success: true, result: 'message'))

      delete :destroy
      expect(flash[:notice]).to include 'message'
      expect(flash[:error]).not_to be_present
      expect(response).to redirect_to controller.send :redirect_path
    end

    it 'calls the service for delete' do
      result = ServiceResult.new(success: false)
      result.errors.add :base, 'error'

      expect_any_instance_of(::Avatars::UpdateService)
        .to receive(:destroy)
        .and_return(result)

      delete :destroy
      expect(response).not_to be_successful
      expect(flash[:notice]).not_to be_present
      expect(flash[:error]).to include 'error'
      expect(response).to redirect_to controller.send :redirect_path
    end
  end
end
