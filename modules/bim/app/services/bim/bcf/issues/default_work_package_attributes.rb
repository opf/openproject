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

      # When creating a topic without an explicit type, prefer a project-specific
      # non-default type over the global standard type ("None").
      def default_create_type(project)
        project.types.where(is_default: false, is_standard: false).first ||
          project.types.default.where(is_standard: false).first ||
          project.types.where(is_standard: false).first ||
          project.types.first
      end

      # PUT requests reset omitted attributes; match the documented default type.
      # When several default types are enabled, prefer the one most recently
      # associated with the project (see ProjectType).
      def default_put_type(project)
        project.project_types
               .joins(:type)
               .merge(Type.default.where(is_standard: false))
               .order(id: :desc)
               .first
               &.type ||
          project.types.default.first ||
          project.types.first
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
