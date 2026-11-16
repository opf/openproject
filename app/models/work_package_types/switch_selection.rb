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

module WorkPackageTypes
  # Projects about to switch a type's variant together. Whether they start from one variant
  # decides the rest: only then can the switch be previewed, or be pointless.
  class SwitchSelection
    attr_reader :type, :projects

    def initialize(type:, projects:)
      @type = type
      @projects = projects.to_a
    end

    def sources
      @sources ||= projects.map { it.type_variant(type) }.uniq
    end

    def single_source? = sources.one?

    def source
      sources.first if single_source?
    end

    # A project-owned variant serves its own project only, so several projects share none.
    def targets
      scope = projects.one? ? type.variants.available_in(projects.first) : type.variants.global
      scope.in_display_order
    end

    def target(id) = targets.find_by(id:)

    def impact(target)
      return if !single_source? || target.nil? || target == source || !targets.exists?(id: target.id)

      ::Projects::Types::Switch::Impact.new(source:, target:, projects:)
    end

    def refusal(target)
      if target.nil?
        I18n.t("types.edit.projects.switch_variant.invalid_target")
      elsif single_source? && target == source
        I18n.t("types.edit.projects.switch_variant.identical", count: projects.size)
      end
    end
  end
end
