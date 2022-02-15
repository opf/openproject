#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

class Storages::Admin::StoragesController < ApplicationController
  layout 'admin'

  model_object Storages::Storage

  before_action :require_admin
  before_action :find_model_object, only: %i[show destroy edit update]

  menu_item :storages_admin_settings

  def index
    @storages = Storages::Storage.all

    render 'storages/admin/index'
  end

  def show
    render 'storages/admin/show'
  end

  def new
    @object = ::Storages::Storages::SetAttributesService
                .new(user: current_user,
                     model: Storages::Storage.new,
                     contract_class: EmptyContract)
                .call({ provider_type: 'nextcloud', name: I18n.t('storages.provider_types.nextcloud') })
                .result

    render 'storages/admin/new'
  end

  def create
    combined_params = permitted_storage_params.to_h.reverse_merge(creator_id: current_user.id)
    service_result = Storages::Storages::CreateService.new(user: current_user).call(combined_params)
    @object = service_result.result

    if service_result.success?
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:notice_successful_create)
          redirect_to storage_path(@object)
        end
      end
    else
      @errors = service_result.errors
      respond_to do |format|
        format.html do
          render 'storages/admin/new'
        end
      end
    end
  end

  def edit
    render 'storages/admin/edit'
  end

  def update
    service_result = ::Storages::Storages::UpdateService
                       .new(user: current_user,
                            model: @object)
                       .call(permitted_storage_params)

    if service_result.success?
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to storage_path(@object)
        end
      end
    else
      respond_to do |format|
        format.html do
          render action: :edit
        end
      end
    end
  end

  def destroy
    Storages::Storages::DeleteService
      .new(user: User.current, model: @object)
      .call

    flash[:info] = I18n.t(:notice_successful_delete)

    respond_to do |format|
      format.html do
        redirect_to storages_path
      end
    end
  end

  def default_breadcrumb
    if action_name == :index
      t(:project_module_storages)
    else
      ActionController::Base.helpers.link_to(t(:project_module_storages), storages_path)
    end
  end

  def show_local_breadcrumb
    true
  end

  private

  def permitted_storage_params
    params
      .require(:storages_storage)
      .permit('name', 'provider_type', 'host')
  end
end
