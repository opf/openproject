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

module Projects
  module Types
    module Switch
      # Projects about to switch a type's variant together. Whether they start from one variant
      # decides the rest: only then can the switch be previewed, or be pointless.
      class Selection
        attr_reader :type, :projects, :user

        def initialize(type:, projects:, user:)
          @type = type
          @projects = projects.to_a
          @user = user
        end

        def sources
          @sources ||= projects.map { it.type_variant(type) }.uniq
        end

        def single_source? = sources.one?

        def source
          sources.first if single_source?
        end

        def targets
          ::TypeVariant.shared_switch_targets(user:, projects:, type:).in_display_order
        end

        def target(id) = targets.find_by(id:)

        # Whether any target would move at least one project.
        def switchable?
          single_source? ? targets.where.not(id: source.id).exists? : targets.exists?
        end

        def moving(target) = projects.reject { it.type_variant(type) == target }

        def impact(target)
          return if !single_source? || target.nil? || target == source

          Impact.new(source:, target:, projects:)
        end

        def refusal(target)
          if target.nil?
            I18n.t("projects.settings.types.switch.invalid_target", count: projects.size)
          elsif single_source? && target == source
            I18n.t("projects.settings.types.switch.identical", count: projects.size)
          end
        end
      end
    end
  end
end
