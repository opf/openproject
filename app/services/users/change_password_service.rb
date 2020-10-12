#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module Users
  class ChangePasswordService
    attr_accessor :current_user
    attr_accessor :session

    def initialize(current_user:, session:)
      @current_user = current_user
      @session = session
    end

    def call(params)
      User.execute_as current_user do
        current_user.password = params[:new_password]
        current_user.password_confirmation = params[:new_password_confirmation]
        current_user.force_password_change = false

        if current_user.save
          log_success
          ::ServiceResult.new success: true,
                              result: current_user,
                              **invalidate_session_result
        else
          log_failure
          ::ServiceResult.new success: false,
                              result: current_user,
                              message: I18n.t(:notice_can_t_change_password),
                              errors: current_user.errors
        end
      end
    end

    private

    def invalidate_session_result
      update_message = I18n.t(:notice_account_password_updated)

      if ::Sessions::DropOtherSessionsService.call(current_user, session)
        expiry_message = I18n.t(:notice_account_other_session_expired)
        { message_type: :info, message: "#{update_message} #{expiry_message}" }
      else
        { message: update_message }
      end
    end

    def log_success
      Rails.logger.info do
        "User #{current_user.login} changed password successfully."
      end
    end

    def log_failure
      Rails.logger.info do
        "User #{current_user.login} failed password change: #{current_user.errors.full_messages.join(', ')}."
      end
    end
  end
end
