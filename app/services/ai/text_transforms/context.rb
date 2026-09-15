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

module AI
  module TextTransforms
    Context = Data.define(:work_package, :project, :type) do
      def self.for_work_package(work_package)
        new(work_package:, project: work_package.project, type: work_package.type)
      end

      def self.for_new_work_package(project:, type:)
        new(work_package: nil, project:, type:)
      end

      def self.none
        new(work_package: nil, project: nil, type: nil)
      end

      def type_variant
        return work_package.type_variant if work_package
        return project.type_variant(type) if project && type

        nil
      end

      def template
        type_variant&.default_work_package_description.presence
      end
    end
  end
end
