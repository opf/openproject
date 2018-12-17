module ::TwoFactorAuthentication
  module ForcedRegistration
    class TwoFactorDevicesController < ::TwoFactorAuthentication::BaseController
      # Require 1FA authenticated user
      prepend_before_action :require_authenticated_user

      # Skip default login
      skip_before_action :check_if_login_required

      before_action :find_device, only: [:confirm]

      ##
      # Avoid dynamic route hitting the base controller
      def make_default
        render_403
      end

      def destroy
        render_403
      end

      ##
      # Register the device and let the user confirm
      def register
        @device_type = params[:key].to_sym
        @device = new_device_type! @device_type

        @device.attributes = new_device_params
        if @device.save
          Rails.logger.info "User ##{target_user.id} forced to register a new (unconfirmed) device #{@device_type}."
          redirect_to action: :confirm, device_id: @device.id
        else
          Rails.logger.warn {"User ##{target_user.id} forced to register failed for #{@device_type}."}
          render 'two_factor_authentication/two_factor_devices/new'
        end
      end

      private

      def target_user
        @authenticated_user
      end

      def show_local_breadcrumb
        false
      end

      def index_path
        two_factor_authentication_request_path
      end

      def registration_success_path
        authentication_stage_complete_path :two_factor_authentication
      end

      def registration_failure_path
        authentication_stage_failure_path :two_factor_authentication
      end

      ##
      # Ensure the authentication stage from the core provided the authenticated user
      def require_authenticated_user
        raise ArgumentError, 'Missing param' unless session[:authenticated_user_force_2fa]
        @authenticated_user = User.find(session[:authenticated_user_id])
        return true
      rescue ActiveRecord::RecordNotFound
        Rails.logger.error "Failed to find authenticated_user for 2FA authentication."
        redirect_to registration_failure_path
        return false
      rescue ArgumentError
        Rails.logger.error "User tried to access forced registration without registration session param set."
        redirect_to registration_failure_path
        return false
      end
    end
  end
end
