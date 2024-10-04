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

# Gives the projects to map and the attributes to be used for the mapping.
module BulkServices
  module ProjectMappings
    class MappingContext < MappingContextBase
      attr_reader :model,
                  :projects,
                  :model_foreign_key_id,
                  :include_sub_projects

      def initialize(mapping_model_class:,
                     model:,
                     projects:,
                     model_foreign_key_id:,
                     include_sub_projects: false)
        super(mapping_model_class:)
        @model = model
        @projects = projects
        @model_foreign_key_id = model_foreign_key_id
        @include_sub_projects = include_sub_projects
      end

      def mapping_attributes_for_all_projects(extra_attributes)
        project_ids_to_map.map do |project_id|
          {
            project_id:,
            model_foreign_key_id => model.id
          }.merge(extra_attributes)
        end
      end

      def incoming_projects
        projects.each_with_object(Set.new) do |project, projects_set|
          next unless project.active?

          projects_set << project
          projects_set.merge(project.active_subprojects.to_a) if include_sub_projects
        end.to_a
      end

      private

      def project_ids_to_map
        project_ids = incoming_projects.pluck(:id)
        project_ids - project_ids_already_mapped(project_ids)
      end

      def project_ids_already_mapped(project_ids)
        mapping_model_class.where(
          model_foreign_key_id => @model.id,
          project_id: project_ids
        ).pluck(:project_id)
      end
    end
  end
end
