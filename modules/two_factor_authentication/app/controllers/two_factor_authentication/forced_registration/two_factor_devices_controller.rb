# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ::TwoFactorAuthentication
  module ForcedRegistration
    class TwoFactorDevicesController < ::TwoFactorAuthentication::BaseController
      # Require 1FA authenticated user
      prepend_before_action :require_authenticated_user

      # Skip default login
      skip_before_action :check_if_login_required
      no_authorization_required! :register,
                                 :new,
                                 :confirm,
                                 :web_authn,
                                 :webauthn_challenge,
                                 :make_default,
                                 :destroy

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
          Rails.logger.info "User ##{target_user.id} forced to register a new (unconfirmed) device #{@device_type}."
          if needs_confirmation
            redirect_to action: :confirm, device_id: @device.id
          else
            flash[:notice] = t("two_factor_authentication.devices.registration_complete")
            @device.confirm_registration_and_save
            redirect_to registration_success_path
          end
        else
          Rails.logger.warn { "User ##{target_user.id} forced to register failed for #{@device_type}." }
          render "two_factor_authentication/two_factor_devices/new", status: :unprocessable_entity
        end
      end

      private

      def target_user
        @authenticated_user
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
        raise ArgumentError, "Missing param" unless session[:authenticated_user_force_2fa]

        @authenticated_user = User.find(session[:authenticated_user_id])
        true
      rescue ActiveRecord::RecordNotFound
        Rails.logger.error "Failed to find authenticated_user for 2FA authentication."
        redirect_to registration_failure_path
        false
      rescue ArgumentError
        Rails.logger.error "User tried to access forced registration without registration session param set."
        redirect_to registration_failure_path
        false
      end
    end
  end
end
