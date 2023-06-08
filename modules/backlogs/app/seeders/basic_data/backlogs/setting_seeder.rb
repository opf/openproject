#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

      def seed_data!
        backlogs_init_setting!
      end

      def applicable?
        not backlogs_configured?
      end

      def backlogs_init_setting!
        Setting.plugin_openproject_backlogs = backlogs_setting_value
      end

      def backlogs_configured?
        backlogs_setting = Hash(Setting.plugin_openproject_backlogs)
        backlogs_setting['story_types'].present? && backlogs_setting['task_type'].present?
      end

      def backlogs_setting_value
        {
          "story_types" => backlogs_types.map(&:id),
          "task_type" => backlogs_task_type.try(:id),
          "points_burn_direction" => "up",
          "wiki_template" => ""
        }
      end

      def backlogs_types
        type_references = %i[
          default_type_feature
          default_type_epic
          default_type_user_story
          default_type_bug
        ]
        seed_data.find_references(type_references, default: nil).compact
      end

      def backlogs_task_type
        seed_data.find_reference(:default_type_task)
      end
    end
  end
end
