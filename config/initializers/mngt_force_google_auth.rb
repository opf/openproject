# frozen_string_literal: true

# Forces Google OAuth as the only authentication method when
# GOOGLE_OAUTH_CLIENT_ID is configured. Blocks all password-based
# login, password reset and password change flows.

Rails.application.config.to_prepare do
  next unless ENV["GOOGLE_OAUTH_CLIENT_ID"].present?

  # Tell OpenProject's own templates to hide the password form.
  OpenProject::Configuration.singleton_class.prepend(Module.new do
    def disable_password_login?
      true
    end
  end)

  # Block direct password login (belt-and-suspenders in case someone
  # hits POST /login manually or via curl).
  AccountController.prepend(Module.new do
    def login
      if request.post? && params[:username].present?
        flash[:error] = "O login com senha está desabilitado. Use o botão Google."
        redirect_to signin_path
      else
        super
      end
    end

    # Disable the "esqueci minha senha" flow — it makes no sense
    # when password login is not allowed.
    def lost_password
      flash[:notice] = "Use o botão Google para entrar."
      redirect_to signin_path
    end
  end)

  # Block the "alterar senha" page in the user profile.
  MyController.prepend(Module.new do
    def password
      flash[:notice] = "O login é feito exclusivamente via Google."
      redirect_to my_account_path
    end
  end)
end
