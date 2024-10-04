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

module Storages::LastProjectFolders
  class BulkCreateService < ::BulkServices::ProjectMappings::BaseCreateService
    attr_reader :something

    def initialize(user:, project_storages:)
      super(user:, mapping_context: ProjectStoragesMappingContext.new(project_storages))
    end

    def permission = :manage_files_in_project

    private

    def perform_bulk_create(service_call)
      bulk_insertion = mapping_model_class.insert_all(
        service_call.result.map { |model| model.attributes.compact },
        returning: %w[id]
      )
      service_call.result = mapping_model_class.where(id: bulk_insertion.rows.flatten)

      service_call
    end
  end
end
