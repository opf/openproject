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

module BasicData
  module Backlogs
    class SettingSeeder < ::Seeder
      self.needs = [
        BasicData::TypeSeeder
      ]

      BACKLOGS_SETTINGS_KEYS = %w[
        story_types
        task_type
        points_burn_direction
        wiki_template
      ].freeze

      def seed_data!
        configure_backlogs_settings
      end

      def applicable?
        not backlogs_configured?
      end

      private

      def configure_backlogs_settings
        Setting.plugin_openproject_backlogs = current_backlogs_settings.merge(missing_backlogs_settings)
      end

      def backlogs_configured?
        BACKLOGS_SETTINGS_KEYS.all? { configured?(_1) }
      end

      def configured?(key)
        current_backlogs_settings[key] != nil
      end

      def current_backlogs_settings
        Hash(Setting.plugin_openproject_backlogs)
      end

      def missing_backlogs_settings
        BACKLOGS_SETTINGS_KEYS
          .reject { |key| configured?(key) }
          .index_with { |key| setting_value(key) }
          .compact
      end

      def setting_value(setting_key)
        case setting_key
        when "story_types"
          backlogs_story_types.map(&:id)
        when "task_type"
          backlogs_task_type.try(:id)
        when "points_burn_direction"
          "up"
        when "wiki_template"
          ""
        end
      end

      def backlogs_story_types
        type_references = %i[
          default_type_feature
          default_type_epic
          default_type_user_story
          default_type_bug
        ]
        seed_data.find_references(type_references, default: nil).compact
      end

      def backlogs_task_type
        seed_data.find_reference(:default_type_task, default: nil)
      end
    end
  end
end
