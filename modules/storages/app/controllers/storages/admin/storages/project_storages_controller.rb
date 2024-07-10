# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Storages::Admin::Storages::ProjectStoragesController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper

  layout "admin"

  model_object Storages::Storage

  before_action :require_admin
  before_action :find_model_object

  menu_item :external_file_storages

  def index
    @project_query = ProjectQuery.new(
      name: "project-storage-mappings-#{@storage.id}"
    ) do |query|
      query.where(:storages, "=", [@storage.id])
      query.select(:name)
      query.order("lft" => "asc")
    end

    # Prepare data for project_folder_type column
    @project_folder_modes_per_project = Storages::ProjectStorage
      .where(storage_id: @storage.id)
      .pluck(:project_id, :project_folder_mode)
      .to_h
  end

  def new
    @project_storage =
      ::Storages::ProjectStorages::SetAttributesService
        .new(user: current_user, model: ::Storages::ProjectStorage.new, contract_class: EmptyContract)
        .call(storage: @storage)
        .result
    respond_with_dialog Storages::Admin::Storages::AddProjectsModalComponent.new(project_storage: @project_storage)
  end

  def create; end
  def destroy; end

  private

  def find_model_object(object_id = :storage_id)
    super
    @storage = @object
  end
end
