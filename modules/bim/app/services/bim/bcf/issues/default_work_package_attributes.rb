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

module Bim::Bcf
  module Issues
    module DefaultWorkPackageAttributes
      module_function

      # When creating a topic without an explicit type, prefer a type the project does not
      # start new projects with, falling back to its first type by position.
      def default_create_type(project)
        project_types = project.project_types.joins(:type, :variant).order(types: { position: :asc })

        row = project_types.merge(TypeVariant.where(enabled_in_new_projects: false)).first ||
              project_types.first

        row&.type
      end

      # PUT requests reset omitted attributes; match the documented default type.
      # When several default types are enabled, prefer the one most recently
      # associated with the project (see ProjectType).
      def default_put_type(project)
        result = project.project_types
               .joins(:type, :variant)
               .merge(TypeVariant.enabled_in_new_projects)
               .order(id: :desc)
               .first ||
               project.project_types.merge(TypeVariant.enabled_in_new_projects).first ||
               project.project_types.first

        result&.type
      end

      def default_status(project, type:)
        return Status.default unless type

        statuses = project.type_variant(type)&.statuses(include_default: true) || Status.none

        statuses.detect(&:is_default) || statuses.first || Status.default
      end

      def default_priority
        IssuePriority.default
      end
    end
  end
end
