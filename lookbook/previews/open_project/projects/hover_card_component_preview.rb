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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Projects
  # @logical_path OpenProject/Projects
  class HoverCardComponentPreview < ViewComponent::Preview
    SCOPES = %i[visible active].freeze

    def no_hierarchy
      user = FactoryBot.build_stubbed(:admin)
      project = FactoryBot.build_stubbed(:project, :with_status)
      render(::Projects::HoverCardComponent.new(project:, user:))
    end

    def with_hierarchy
      user = FactoryBot.build_stubbed(:admin)
      root = FactoryBot.build_stubbed(:project, name: "Arcanos Flight Planning")
      child = FactoryBot.build_stubbed(:project, name: "Mobile app", parent: root)
      leaf = FactoryBot.build_stubbed(:project, active: false, name: "Data sources", parent: child, status_code: 1)

      chain = [root, child, leaf]

      chain.each_with_index do |project, i|
        ancestors = chain.first(i)
        SCOPES.each { |scope| ancestors.define_singleton_method(scope) { |*| self } }
        ancestors.define_singleton_method(:reorder) { |*| self }
        project.define_singleton_method(:ancestors) { ancestors }
      end

      render(::Projects::HoverCardComponent.new(project: leaf, user:))
    end
  end
end
