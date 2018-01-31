module ::TwoFactorAuthentication
  module My
    class TwoFactorDevicesController < ::TwoFactorAuthentication::BaseController
      # Ensure user is logged in
      before_action :require_login

      before_action :set_user_variables

      before_action :find_device, except: [:new, :index, :register]

      # Remmeber token functionality
      include ::TwoFactorAuthentication::Concerns::RememberToken

      # Password confirmation helpers and actions
      include ::Concerns::PasswordConfirmation
      before_action :check_password_confirmation,
                    only: [:make_default, :destroy]

      # Delete remember token on destroy
      before_action :clear_remember_token!, only: [:destroy]

      layout 'my'
      menu_item :two_factor_authentication

      def index
        @two_factor_devices = @user.otp_devices.reload
        @remember_token = get_2fa_remember_cookie(current_user)
      end

      ##
      # Register the device and let the user confirm
      def register
        @device_type = params[:key].to_sym
        @device = new_device_type! @device_type

        @device.attributes = new_device_params
        if @device.save
          Rails.logger.info "User ##{current_user.id} registered a new (unconfirmed) device #{@device_type}."
          redirect_to action: :confirm, device_id: @device.id
        else
          Rails.logger.warn {"User ##{current_user.id} failed to register a device #{@device_type}."}
          render 'two_factor_authentication/two_factor_devices/new'
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
        request_token_for_device(
            @device,
            confirm_path: url_for(action: :confirm, device_id: @device.id),
            title: I18n.t('two_factor_authentication.devices.confirm_device'),
            message: I18n.t('two_factor_authentication.devices.text_confirm_to_complete_html', identifier: @device.identifier)
        )
      end

      ##
      # Validate the token input
      def validate_device_token
        service = token_service(@device)
        result = service.verify(params[:otp])

        if result.success? && @device.confirm_registration_and_save
          flash[:notice] = t('two_factor_authentication.devices.registration_complete')
          return redirect_to action: :index
        elsif !result.success?
          flash[:error] = t('two_factor_authentication.devices.registration_failed_token_invalid')
        else
          flash[:error] = t('two_factor_authentication.devices.registration_failed_update')
        end

        redirect_to action: :confirm, device_id: @device.id
      end

      def request_token_for_device(device, locals)
        transmit = token_service(device).request

        if transmit.success?
          flash[:notice] = transmit.result if transmit.result.present?

          # Request confirmation from user as in the regular login flow
          render 'two_factor_authentication/two_factor_devices/confirm', layout: 'base', locals: locals
        else
          error = transmit.errors.full_messages.join(". ")
          default_message = t('two_factor_authentication.devices.confirm_send_failed')
          flash[:error] = "#{default_message} #{error}"

          redirect_to action: :index
        end
      end

      def index_path
        url_for action: :index
      end

      def set_user_variables
        @user = current_user
        @default_device = @user.otp_devices.get_default
      end
    end
  end
end
