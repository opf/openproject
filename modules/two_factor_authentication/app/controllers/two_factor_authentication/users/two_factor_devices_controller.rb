module ::TwoFactorAuthentication
  module Users
    class TwoFactorDevicesController < ::TwoFactorAuthentication::BaseController
      # Require admin status to edit users' 2FA
      before_action :require_admin

      # Ensure where not the user under edit
      before_action :require_not_self

      # Password confirmation helpers and actions
      include ::Concerns::PasswordConfirmation
      before_action :check_password_confirmation,
                    only: :make_default

      # Skip before action on delete_all
      skip_before_action :find_device, only: [:delete_all]

      def index
      end

      ##
      # Register the device and let the user confirm
      def register
        @device_type = params[:key].to_sym
        @device = new_device_type! @device_type

        @device.attributes = new_device_params
        if @device.confirm_registration_and_save
          Rails.logger.info "Admin ##{current_user.id} registered a new device #{@device_type} for #{@user.id}."
          redirect_to index_path
        else
          Rails.logger.info "Admin ##{current_user.id} failed to register a new device #{@device_type} for #{@user.id}."
          render 'two_factor_authentication/two_factor_devices/new'
        end
      end

      ##
      # Delete all devices
      def delete_all
        @user.otp_devices.delete_all
        flash[:notice] = I18n.t('two_factor_authentication.admin.all_devices_deleted')
        redirect_to index_path
      end

      ##
      # Confirm the change of the default device
      # using the token on it.
      # Subject to password confirmation if the user supports it.
      def make_default
        if @device.make_default!
          flash[:notice] = t(:notice_successful_update)
        else
          flash[:error] = t('two_factor_authentication.devices.make_default_failed')
        end

        redirect_to index_path
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

        redirect_to confirm_two_factor_device_path(@device)
      end

      ##
      # Destroy the given device if its not the default
      def destroy
        if @device.default && strategy_manager.enforced?
          render_400 message: t('two_factor_authentication.devices.is_default_cannot_delete')
          return
        end

        if @device.destroy
          flash[:notice] = t(:notice_successful_delete)
        else
          flash[:error] = t('two_factor_authentication.devices.failed_to_delete')
          Rails.logger.error "Failed to delete #{@device.id} of user#{@user.id}. Errors: #{@device.errors.full_messages.join(' ')}"
        end

        redirect_to index_path
      end

      private

      def new_device_params
        # Overrides the base controller to active the device
        # without prior confirmation.
        permitted_device_params.merge(
            user: @user,
            active: true
        )
      end

      def index_path
        edit_user_path(@user, tab: :two_factor_authentication)
      end

      def find_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def target_user
        @user
      end

      def require_not_self
        if current_user.id == @user.id
          render_403(message: I18n.t('two_factor_authentication.admin.self_edit_forbidden'))
        end
      end
    end
  end
end
