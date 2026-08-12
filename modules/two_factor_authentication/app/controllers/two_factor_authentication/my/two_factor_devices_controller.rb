# frozen_string_literal: true

module ::TwoFactorAuthentication
  module My
    class TwoFactorDevicesController < ::TwoFactorAuthentication::BaseController
      # Ensure user is logged in
      before_action :require_login
      before_action :set_user_variables
      # Authorization is not handled explicitly but as the user on which changes can be done is only the current user
      # (and that user needs to be logged in), no action harmful to other users can be done.
      no_authorization_required! :new,
                                 :create,
                                 :register,
                                 :confirm,
                                 :destroy,
                                 :make_default,
                                 :webauthn_challenge

      before_action :find_device, except: %i[new register webauthn_challenge]

      # Remember token functionality
      include ::TwoFactorAuthentication::RememberToken

      # Password confirmation helpers and actions
      include PasswordConfirmation
      before_action :check_password_confirmation,
                    only: %i[make_default destroy]

      # Delete remember token on destroy
      before_action :clear_remember_token!, only: [:destroy]

      layout "my"
      menu_item :security

      ##
      # Register the device and let the user confirm
      def register # rubocop:disable Metrics/AbcSize
        @device_type = params[:key].to_sym
        @device = new_device_type! @device_type

        needs_confirmation = true

        if @device_type == :webauthn
          if verify_webauthn_credential
            @device.attributes = new_webauthn_device_params
            needs_confirmation = false
          end
        else
          @device.attributes = new_device_params
        end

        if @device.save
          Rails.logger.info "User ##{current_user.id} registered a new (unconfirmed) device #{@device_type}."

          if needs_confirmation
            redirect_to action: :confirm, device_id: @device.id
          else
            flash[:notice] = t("two_factor_authentication.devices.registration_complete")
            @device.confirm_registration_and_save
            redirect_to registration_success_path
          end
        else
          Rails.logger.warn { "User ##{current_user.id} failed to register a device #{@device_type}." }
          render "two_factor_authentication/two_factor_devices/new", status: :unprocessable_entity
        end
      end

      ##
      # Send a confirmation and request a OTP entry from the user to activate the device
      def confirm
        if request.get?
          request_device_confirmation_token
        else
          return unless ensure_token_parameter

          validate_device_token
        end
      end

      private

      ##
      # Request (if needed) the token for entering
      def request_device_confirmation_token
        request_token_for_device(@device, confirm_path: url_for(action: :confirm, device_id: @device.id))
      end

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

          redirect_to index_path
        end
      end

      def index_path
        my_security_path
      end

      def registration_success_path
        my_security_path
      end

      def set_user_variables
        @user = current_user
        @default_device = @user.otp_devices.get_default
      end
    end
  end
end
