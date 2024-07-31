module ::TwoFactorAuthentication
  class BaseController < ApplicationController
    include ::TwoFactorAuthentication::WebauthnRelyingParty

    # Ensure 2FA authentication is enabled
    before_action :ensure_enabled_2fa

    # Locate the user we're editing
    prepend_before_action :find_user

    before_action :find_device, only: %i[confirm make_default destroy]

    helper_method :optional_webauthn_challenge_url

    layout "no_menu"

    def new
      if params[:type]
        @device_type = params[:type].to_sym
        @device = new_device_type! @device_type
        render "two_factor_authentication/two_factor_devices/new"
      else
        @available_devices = available_devices
        render "two_factor_authentication/two_factor_devices/new_type"
      end
    end

    ##
    # Confirm the change of the default device
    # using the token on it.
    # Subject to password confirmation if the user supports it.
    def make_default
      if @device.make_default!
        flash[:notice] = t(:notice_successful_update)
      else
        flash[:error] = t("two_factor_authentication.devices.make_default_failed")
      end

      redirect_to index_path
    end

    ##
    # Destroy the given device if its not the default
    def destroy
      if @device.default && strategy_manager.enforced?
        render_400 message: t("two_factor_authentication.devices.is_default_cannot_delete")
        return
      end

      if @device.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = t("two_factor_authentication.devices.failed_to_delete")
        Rails.logger.error "Failed to delete #{@device.id} of user#{target_user.id}. Errors: #{@device.errors.full_messages.join(' ')}"
      end

      redirect_to index_path
    end

    ##
    # Send a confirmation and request a OTP entry from the user to activate the device
    def confirm
      if request.get?
        request_device_confirmation_token
      elsif request.post?
        return unless ensure_token_parameter

        validate_device_token
      else
        head :method_not_allowed
      end
    end

    def webauthn_challenge
      device = new_device_type!(:webauthn)

      ensure_user_has_webauthn_id!

      webauthn_options = device.options_for_create(webauthn_relying_party)
      session[:webauthn_challenge] = webauthn_options.challenge

      render json: webauthn_options
    end

    private

    ##
    # Request (if needed) the token for entering
    def request_device_confirmation_token
      request_token_for_device(
        @device,
        confirm_path: url_for(action: :confirm, device_id: @device.id),
        title: I18n.t("two_factor_authentication.devices.confirm_device"),
        message: I18n.t("two_factor_authentication.devices.text_confirm_to_complete_html", identifier: @device.identifier)
      )
    end

    ##
    # Validate the token input
    def validate_device_token
      service = token_service(@device)
      result = service.verify(params[:otp])

      has_default = ::TwoFactorAuthentication::Device.has_default?(target_user)
      if confirm_and_save(result)
        logout_other_sessions unless has_default
        redirect_to registration_success_path
      else
        redirect_to action: :confirm, device_id: @device.id
      end
    end

    # rubocop:disable Metrics/AbcSize
    def confirm_and_save(result)
      if result.success? && @device.confirm_registration_and_save
        flash[:notice] = t("two_factor_authentication.devices.registration_complete")
        true
      elsif !result.success?
        flash[:notice] = nil
        flash[:error] = t("two_factor_authentication.devices.registration_failed_token_invalid")
        false
      else
        flash[:notice] = nil
        flash[:error] = t("two_factor_authentication.devices.registration_failed_update")
        false
      end
    end
    # rubocop:enable Metrics/AbcSize

    def request_token_for_device(device, locals)
      transmit = token_service(device).request

      if transmit.success?
        flash[:notice] = transmit.result if transmit.result.present?

        # Request confirmation from user as in the regular login flow
        render "two_factor_authentication/two_factor_devices/confirm", layout: "base", locals:
      else
        error = transmit.errors.full_messages.join(". ")
        default_message = t("two_factor_authentication.devices.confirm_send_failed")
        flash[:error] = "#{default_message} #{error}"

        redirect_to registration_failure_path
      end
    end

    def index_path
      raise NotImplementedError
    end

    helper_method :index_path

    def registration_failure_path
      index_path
    end

    def registration_success_path
      index_path
    end

    def new_device_params
      permitted_device_params.merge(
        user: target_user,
        default: false,
        active: false
      )
    end

    def new_webauthn_device_params
      permitted_device_params.merge(
        user: target_user,
        default: false,
        active: true,
        webauthn_external_id: webauthn_credential.id,
        webauthn_public_key: webauthn_credential.public_key,
        webauthn_sign_count: webauthn_credential.sign_count
      )
    end

    def webauthn_credential
      @webauthn_credential ||= webauthn_relying_party.verify_registration(
        JSON.parse(params[:device][:webauthn_credential]),
        session[:webauthn_challenge]
      )
    end

    def verify_webauthn_credential
      if webauthn_credential
        session.delete(:webauthn_challenge)
        true
      else
        false
      end
    rescue WebAuthn::Error => e
      Rails.logger.error "Failed to verify WebAuthn credential for registration. #{e}"
      false
    end

    def logout_other_sessions
      if current_user == target_user
        Rails.logger.info { "First 2FA device registered for #{target_user}, terminating other logged in sessions." }
        ::Sessions::DropOtherSessionsService.call!(target_user, session)
      else
        Rails.logger.info { "First 2FA device registered for #{target_user}, terminating logged in sessions." }
        ::Sessions::DropAllSessionsService.call!(target_user)
      end
    end

    def permitted_device_params
      params.require(:device).permit(:phone_number, :channel, :otp_secret, :identifier)
    end

    def ensure_token_parameter
      unless params[:otp].present?
        redirect_to registration_failure_path
        return false
      end

      true
    end

    def new_device_type!(type)
      if available_devices.key? type
        return available_devices[type].new(default: false, user: target_user)
      end

      render_400
    end

    def find_device
      @device = target_user.otp_devices.find(params[:device_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def find_user
      true
    end

    def target_user
      current_user
    end

    def show_local_breadcrumb
      true
    end

    def default_breadcrumb
      t("two_factor_authentication.label_devices")
    end

    def available_devices
      strategy_manager.available_devices
    end

    def strategy_manager
      ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
    end

    def ensure_enabled_2fa
      render_404 unless strategy_manager.enabled?
    end

    def token_service(device)
      ::TwoFactorAuthentication::TokenService.new user: target_user, use_device: device
    end

    def ensure_user_has_webauthn_id!
      return if target_user.webauthn_id

      target_user.update(webauthn_id: WebAuthn.generate_user_id)
    end

    def optional_webauthn_challenge_url
      if @device_type == :webauthn
        helpers.url_for(action: :webauthn_challenge, format: :json)
      end
    end
  end
end
