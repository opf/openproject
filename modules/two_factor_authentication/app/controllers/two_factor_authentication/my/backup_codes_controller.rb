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
  module My
    class BackupCodesController < ::ApplicationController
      # Ensure user is logged in
      before_action :require_login
      no_authorization_required! :show, :create

      # Password confirmation helpers and actions
      include PasswordConfirmation
      before_action :check_password_confirmation, only: [:create]

      # Verify that flash was set (coming from create)
      before_action :check_regenerate_done, only: [:show]

      layout "my"
      menu_item :security

      def create
        flash[:_backup_codes] = TwoFactorAuthentication::BackupCode.regenerate!(current_user)
        redirect_to action: :show
      end

      def show
        render
      end

      private

      def check_regenerate_done
        @backup_codes = flash[:_backup_codes]
        flash.delete :_backup_codes

        unless @backup_codes.present?
          flash[:error] = I18n.t(:notice_bad_request)
          redirect_to my_security_path
        end
      end
    end
  end
end
