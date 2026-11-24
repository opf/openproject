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

module Admin
  class SecurityLevelMembersController < ::ApplicationController
    before_action :require_admin
    before_action :find_level

    def create
      principal = find_principal
      membership = @level.security_level_principals.build(principal:)

      if principal && membership.save
        flash[:notice] = t(:notice_successful_create)
      else
        flash[:error] = t(:notice_unsuccessful_update)
      end

      redirect_to level_path
    end

    def destroy
      @level.security_level_principals.find(params.expect(:id)).destroy!
      flash[:notice] = t(:notice_successful_delete)

      redirect_to level_path
    end

    private

    def find_level
      @scheme = SecurityLevelScheme.find(params.expect(:security_level_scheme_id))
      @level = @scheme.security_levels.find(params.expect(:security_level_id))
    end

    def find_principal
      Principal.where(type: [User.name, Group.name]).find_by(id: params.dig(:member, :principal_id))
    end

    def level_path
      edit_admin_security_level_scheme_security_level_path(@scheme, @level)
    end
  end
end
