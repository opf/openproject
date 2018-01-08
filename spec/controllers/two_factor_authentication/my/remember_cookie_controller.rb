require_relative '../../../spec_helper'
require_relative './../authentication_controller_shared_examples'

describe ::TwoFactorAuthentication::My::RememberCookieController do
  let(:user) { FactoryGirl.create(:user, login: 'foobar') }
  let(:logged_in_user) { user }

  before do
    allow(User).to receive(:current).and_return(logged_in_user)
  end

  describe '#destroy' do
    before do
      delete :destroy
    end

    context 'when not logged in' do
      let(:logged_in_user) { User.anonymous }
      it 'does not give access' do
        expect(response).to be_redirect
        expect(response).to redirect_to signin_path(back_url: my_2fa_remember_cookie_url)
      end
    end

    context 'when logged in and active strategies' do
      it 'renders the index page' do
        expect(response).to be_redirect
        expect(flash[:notice]).to be_present
      end
    end
  end
end
