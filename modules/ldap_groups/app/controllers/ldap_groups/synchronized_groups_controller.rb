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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
module LdapGroups
  class SynchronizedGroupsController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    guard_enterprise_feature(:ldap_groups, except: %i[index show destroy]) do
      redirect_to action: :index, status: :see_other
    end

    before_action :find_group, only: %i(show edit update destroy_info destroy)

    layout "admin"
    menu_item :plugin_ldap_groups
    include PaginationHelper

    def index
      @groups = SynchronizedGroup.includes(:ldap_auth_source, :group)
      @filters = SynchronizedFilter.includes(:ldap_auth_source, :groups)
    end

    def show; end

    def new
      @group = SynchronizedGroup.new
    end

    def edit; end

    def create
      @group = SynchronizedGroup.new permitted_params

      if @group.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to action: :index
      else
        render action: :new, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def update
      if @group.update(permitted_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: :show
      else
        render action: :edit, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def destroy_info
      respond_with_dialog LdapGroups::SynchronizedGroups::DestroyDialogComponent.new(group: @group)
    end

    def destroy
      if @group.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_can_not_delete_entry)
      end

      redirect_to action: :index
    end

    private

    def find_group
      @group = SynchronizedGroup.find(params[:ldap_group_id])
    end

    def permitted_params
      params.expect(synchronized_group: %i[dn group_id ldap_auth_source_id sync_users])
    end
  end
end
