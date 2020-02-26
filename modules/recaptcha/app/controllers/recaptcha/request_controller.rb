require 'recaptcha'

module ::Recaptcha
  class RequestController < ApplicationController
    # Include global layout helper
    layout 'no_menu'

    # User is not yet logged in, so skip login required check
    skip_before_action :check_if_login_required

    # Skip if recaptcha was disabled
    before_action :skip_if_disabled

    # Require authenticated user from the core to be present
    before_action :require_authenticated_user

    # Skip if user is admin
    before_action :skip_if_admin

    # Skip if user has confirmed already
    before_action :skip_if_user_verified

    ##
    # Request verification form
    def perform
      use_content_security_policy_named_append(:recaptcha)
    end

    def verify
      if valid_recaptcha?
        save_recpatcha_verification_success!
        complete_stage_redirect
      else
        fail_recaptcha I18n.t('recaptcha.error_captcha')
      end
    end

    private

    ##
    # Insert that the account was verified
    def save_recpatcha_verification_success!
      # Remove all previous
      ::Recaptcha::Entry.where(user_id: @authenticated_user.id).delete_all
      ::Recaptcha::Entry.create!(user_id: @authenticated_user.id, version: recaptcha_version)
    end

    def recaptcha_version
      case recaptcha_settings[:recaptcha_type]
      when ::OpenProject::Recaptcha::TYPE_DISABLED
        0
      when ::OpenProject::Recaptcha::TYPE_V2
        2
      when ::OpenProject::Recaptcha::TYPE_V3
        3
      end
    end

    ##
    #
    def valid_recaptcha?
      call_args = { secret_key: recaptcha_settings[:secret_key] }
      if recaptcha_version == 3
        call_args[:action] = 'login'
      end

      verify_recaptcha call_args
    end

    ##
    # fail the recaptcha
    def fail_recaptcha(msg)
      flash[:error] = msg
      failure_stage_redirect
    end

    ##
    # Ensure the authentication stage from the core provided the authenticated user
    def require_authenticated_user
      @authenticated_user = User.find(session[:authenticated_user_id])
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Failed to find authenticated_user for recaptcha verify."
      failure_stage_redirect
    end

    def recaptcha_settings
      Setting.plugin_openproject_recaptcha
    end

    def skip_if_disabled
      if recaptcha_settings[:recaptcha_type] == ::OpenProject::Recaptcha::TYPE_DISABLED
        complete_stage_redirect
      end
    end

    def skip_if_admin
      if @authenticated_user&.admin?
        complete_stage_redirect
      end
    end

    def skip_if_user_verified
      if ::Recaptcha::Entry.where(user_id: @authenticated_user.id).exists?
        Rails.logger.debug { "User #{@authenticated_user.id} already provided recaptcha. Skipping. " }
        complete_stage_redirect
      end
    end

    ##
    # Complete this authentication step and return to core
    # logging in the user
    def complete_stage_redirect
      redirect_to authentication_stage_complete_path :recaptcha
    end

    def failure_stage_redirect
      redirect_to authentication_stage_failure_path :recaptcha
    end
  end
end
