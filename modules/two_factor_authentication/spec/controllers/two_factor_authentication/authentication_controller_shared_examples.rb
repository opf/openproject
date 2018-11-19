require_relative '../../spec_helper'

shared_examples 'immediate success login' do
  context 'with valid credentials' do
    it "should not yet log in user" do
      expect(User.current).not_to eq(user)
    end

    it "should not render flash error message" do
      expect(flash[:error]).not_to be_present
    end

    it "should render redirect" do
      expect(response).to redirect_to stage_success_path(stage: :two_factor_authentication, secret: 'asdf')
    end
  end
end

shared_examples '2FA forced registry' do
  it "should not log in user" do
    expect(User.current).not_to eq(user) end

  it "should set authenticated user" do
    expect(session[:authenticated_user_force_2fa]).to be_truthy
    expect(session[:authenticated_user_id]).to eq user.id
  end

  it "should flash info message" do
    expect(flash[:info]).not_to be_empty
  end

  it "should render the login_otp" do
    expect(response).to redirect_to new_forced_2fa_device_path
  end
end

shared_examples '2FA response failure' do |expected_error|
  it "should not log in user" do
    expect(User.current).not_to eq(user)
  end

  it "should flash error message" do
    expect(flash[:error]).not_to be_empty
    expect(flash[:error]).to include expected_error
  end

  it "should render the login_otp" do
    expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
  end
end

shared_examples '2FA login request failure' do |expected_error|
  before do
    session[:authenticated_user_id] = user.id
    get :request_otp
  end

  it_behaves_like '2FA response failure', expected_error
end

shared_examples '2FA credentials authentication success' do
  describe 'requesting the token' do
    before do
      session[:authenticated_user_id] = user.id
      get :request_otp
    end

    it "should not log in user" do
      expect(User.current).not_to eq(user)
    end

    it "should print the success message" do
      expect(flash[:error]).not_to be_present
    end

    it "should render the login_otp" do
      expect(response).to render_template 'request_otp'
    end
  end
end

shared_examples '2FA login_otp fails without authenticated user' do
  describe 'follow-up post of the login token without authenticated user' do
    before do
      # Assume the user is NOT pending
      session[:authenticated_user_id] = nil
      post :confirm_otp, params: { otp: 'does not matter' }
    end

    it "should redirect to login page" do
      expect(response).to redirect_to stage_failure_path(stage: :two_factor_authentication)
    end

    it "should not log in user" do
      expect(User.current).not_to eq(user)
    end
  end
end

shared_examples '2FA TOTP request success' do
  # 1FA redirects to login_otp
  it_behaves_like '2FA credentials authentication success'

  # Cannot post to login_otp without authenticated user session
  it_behaves_like '2FA login_otp fails without authenticated user'

  # Can post to login_otp with pending and token
  describe 'follow-up post of a login token' do

    before do
      # Assume the user is pending
      session[:authenticated_user_id] = user.id
      # Post the token
      post :confirm_otp, params: { otp: token }
    end

    context 'with a valid token' do
      let(:token) { device.totp.now }
      it_behaves_like 'immediate success login'
    end

    context 'with an invalid token' do
      let(:token) { 'bogus' }
      it_behaves_like '2FA response failure', I18n.t(:notice_account_otp_invalid)
    end
  end
end

shared_examples '2FA SMS request success' do
  # 1FA redirects to login_otp
  it_behaves_like '2FA credentials authentication success'

  # Cannot post to login_otp without pending user session
  it_behaves_like '2FA login_otp fails without authenticated user'

  describe 'follow-up post of a login token' do
    let(:valid_token) { instance_double(::TwoFactorAuthentication::LoginToken, value: '123456') }

    before do
      # Assume the user is pending
      session[:authenticated_user_id] = user.id
    end

    context 'with a valid token' do
      before do
        # Return the value upon find
        expect(::TwoFactorAuthentication::LoginToken)
          .to receive(:find_by_plaintext_value)
          .with(valid_token.value)
          .and_return(valid_token)
        allow(valid_token).to receive(:destroy)
        allow(valid_token).to receive(:expired?).and_return(expired)
        post :confirm_otp, params: { otp: valid_token.value }
      end


      context 'when not expired' do
        let(:expired) { false }
        it_behaves_like 'immediate success login'
      end

      context 'when expired' do
        let(:expired) { true }
        it_behaves_like '2FA response failure', I18n.t(:notice_account_otp_invalid)
      end
    end

    context 'with an invalid token' do
      before do
        # Return the value upon find
        expect(::TwoFactorAuthentication::LoginToken)
          .to receive(:find_by_plaintext_value)
          .with('bogus')
          .and_return(nil)

        post :confirm_otp, params: { otp: 'bogus' }
      end

      it_behaves_like '2FA response failure', I18n.t(:notice_account_otp_invalid)
    end
  end
end
