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

module Storages
  module LastProjectFolders
    class ProjectStoragesMappingContext < BulkServices::ProjectMappings::MappingContextBase
      attr_reader :project_storages

      def initialize(project_storages)
        super(mapping_model_class: ::Storages::LastProjectFolder)
        @project_storages = project_storages
      end

      def mapping_attributes_for_all_projects(_params)
        project_storages.map do |project_storage|
          {
            project_storage_id: project_storage.id,
            origin_folder_id: project_storage.project_folder_id,
            mode: project_storage.project_folder_mode
          }
        end
      end

      def incoming_projects
        @incoming_projects ||= Project.where(id: project_storages.pluck(:project_id))
      end
    end
  end
end
