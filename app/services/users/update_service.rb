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
  class UpdateService
    include ::HookHelper

    attr_accessor :current_user

    def initialize(current_user:)
      @current_user = current_user
    end

    def call(permitted_params, params)
      User.execute_as current_user do
        set_attributes(permitted_params, params)
      end
    end

    private

    def set_attributes(permitted_params, params)
      current_user.attributes = permitted_params.user
      current_user.pref.attributes = if params[:pref].present?
                                       permitted_params.pref
                                     else
                                       {}
                                     end

      call_hook :service_update_user_before_save,
                params: params,
                permitted_params: permitted_params,
                user: current_user

      if current_user.save
        success = current_user.pref.save
        ServiceResult.new(success: success, errors: current_user.errors, result: current_user)
      else
        ServiceResult.new(success: false, errors: current_user.errors, result: current_user)
      end
    end
  end
end
