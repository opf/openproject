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

class LdapAuthSourcesController < ApplicationController
  menu_item :ldap_authentication
  include PaginationHelper
  layout "admin"

  before_action :require_admin
  before_action :block_if_password_login_disabled

  self._model_object = LdapAuthSource
  before_action :find_model_object, only: %i(edit update destroy)
  before_action :prevent_editing_when_seeded, only: %i(update)

  def index
    @ldap_auth_sources = LdapAuthSource
      .order(id: :asc)
      .page(page_param)
      .per_page(per_page_param)
  end

  def new
    @ldap_auth_source = LdapAuthSource.new
  end

  def edit; end

  def create
    @ldap_auth_source = LdapAuthSource.new permitted_params.ldap_auth_source
    if @ldap_auth_source.save
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to action: "index"
    else
      render "new"
    end
  end

  def update
    @ldap_auth_source = LdapAuthSource.find(params[:id])
    updated = permitted_params.ldap_auth_source
    updated.delete :account_password if updated[:account_password].blank?

    if @ldap_auth_source.update updated
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: "index"
    else
      render "edit"
    end
  end

  def test_connection
    @auth_method = LdapAuthSource.find(params[:id])
    begin
      @auth_method.test_connection
      flash[:notice] = I18n.t(:notice_successful_connection)
    rescue StandardError => e
      flash[:error] = I18n.t(:error_unable_to_connect, value: e.message)
    end
    redirect_to action: "index"
  end

  def destroy
    @ldap_auth_source = LdapAuthSource.find(params[:id])
    if @ldap_auth_source.users.empty?
      @ldap_auth_source.destroy

      flash[:notice] = t(:notice_successful_delete)
    else
      flash[:warning] = t(:notice_wont_delete_auth_source)
    end
    redirect_to action: "index"
  end

  protected

  def prevent_editing_when_seeded
    if @ldap_auth_source.seeded_from_env?
      flash[:warning] = I18n.t(:label_seeded_from_env_warning)
      redirect_to action: :index
    end
  end

  def show_local_breadcrumb
    false
  end

  def block_if_password_login_disabled
    render_404 if OpenProject::Configuration.disable_password_login?
  end
end
