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

# frozen_string_literal: true

module TypeSchemes
  module Resolver
    module_function

    def for_project(project)
      return if project.nil?

      ProjectTypeScheme.includes(scheme: { items: :type }).find_by(project_id: project.id)
                       &.scheme&.then { |s| s if s.active }
    end

    # Returns +scope+ untouched when no scheme applies, so project settings stay native.
    def allowed_types(project, scope = project.enabled_types)
      scheme = for_project(project)
      return scope unless scheme

      by_id = scope.index_by(&:id)
      ordered = scheme.items.sort_by { |i| [i.is_default ? 0 : 1, i.position] }
                      .filter_map { |i| by_id[i.type_id] }
      ordered.presence || scope
    end
  end
end
