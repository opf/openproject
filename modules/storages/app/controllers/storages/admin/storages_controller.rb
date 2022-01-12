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
  before_action :require_admin
  menu_item :storages_settings

  def index
    @storages = Storages::Storage.all
    render 'storages/admin/index'
  end

  def show
    @storage = Storages::Storage.find_by id: params[:id]
    render 'storages/admin/show'
  end

  def new
    @storage = Storages::Storage.new(provider_type: 'nextcloud', name: I18n.t('storages.provider_types.nextcloud'))
    render 'storages/admin/new'
  end

  def create
    combined_params = permitted_storage_params
                        .to_h
                        .reverse_merge(creator_id: current_user.id)

    @storage = Storages::Storage.create combined_params
    redirect_to storage_path(@storage)
  end

  def update
    # tbd
  end

  def delete
    # tbd
  end

  def default_breadcrumb
    t(:project_module_storages)
  end

  def show_local_breadcrumb
    true
  end

  private

  def permitted_storage_params
    params
      .require(:storages_storage)
      .permit('name', 'provider_type')
  end
end
