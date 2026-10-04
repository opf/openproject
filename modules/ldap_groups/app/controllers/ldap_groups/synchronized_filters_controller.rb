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

module LdapGroups
  class SynchronizedFiltersController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    guard_enterprise_feature(:ldap_groups, except: %i[show destroy]) do
      redirect_to ldap_groups_synchronized_groups_path, status: :see_other
    end

    before_action :find_filter, except: %i[new create]

    layout "admin"
    menu_item :plugin_ldap_groups

    def show; end

    def new
      @filter = SynchronizedFilter.new
    end

    def end; end

    def destroy_info
      respond_with_dialog LdapGroups::SynchronizedFilters::DestroyDialogComponent.new(filter: @filter)
    end

    def create
      @filter = SynchronizedFilter.new permitted_params

      if @filter.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to ldap_groups_synchronized_groups_path
      else
        render action: :new, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def update
      if @filter.update permitted_params
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: :show
      else
        render action: :edit, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing
      render_400
    end

    def destroy
      if @filter.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_can_not_delete_entry)
      end

      redirect_to ldap_groups_synchronized_groups_path, status: :see_other
    end

    def synchronize
      call = ::LdapGroups::SynchronizeFilterService
                .new(@filter)
                .call

      call.on_success do
        count = call.result
        symbol = count > 0 ? :notice : :info
        flash[symbol] = I18n.t("ldap_groups.synchronized_filters.label_n_groups_found", count:)
      end

      call.on_failure do
        flash[:error] = call.message
      end

      redirect_to ldap_groups_synchronized_groups_path
    end

    private

    def find_filter
      @filter = SynchronizedFilter.find(params.expect(:ldap_filter_id))
    end

    def permitted_params
      params.expect(synchronized_filter: %i[filter_string
                                            name
                                            ldap_auth_source_id
                                            group_name_attribute
                                            sync_users
                                            base_dn
                                            member_lookup_attribute])
    end
  end
end
