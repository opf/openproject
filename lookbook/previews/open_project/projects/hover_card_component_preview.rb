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

    # @param archived [boolean]
    def no_hierarchy(archived: false)
      project = FactoryBot.build_stubbed(:project, status_code: :on_track, status_explanation: "some explanation",
                                                   active: !archived)
      render(::Projects::HoverCardComponent.new(project:))
    end

    # @param archived [boolean]
    def with_hierarchy(archived: false)
      root = FactoryBot.build_stubbed(:project, name: "Arcanos Flight Planning")
      child = FactoryBot.build_stubbed(:project, name: "Mobile app", parent: root)
      leaf = FactoryBot.build_stubbed(:project, active: !archived, name: "Data sources", parent: child, status_code: :on_track,
                                                status_explanation: "some explanation")

      chain = [root, child, leaf]

      chain.each_with_index do |project, i|
        ancestors = chain.first(i)
        SCOPES.each { |scope| ancestors.define_singleton_method(scope) { |*| self } }
        ancestors.define_singleton_method(:reorder) { |*| self }
        project.define_singleton_method(:ancestors) { ancestors }
      end

      render(::Projects::HoverCardComponent.new(project: leaf))
    end
  end
end
