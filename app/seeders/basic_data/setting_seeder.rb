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
  class SettingSeeder < Seeder
    def seed_data!
      Setting.transaction do
        settings_not_in_db.each do |setting_name|
          datum = data[setting_name]

          Setting[setting_name.to_sym] = datum
        end
      end
    end

    def applicable?
      settings_not_in_db.any?
    end

    def not_applicable_message
      'Skipping settings as all settings already exist in the db'
    end

    def data
      @data ||= begin
        settings = seedable_setting_definitions.each_with_object({}) do |definition, hash|
          hash[definition.name] = definition.value
        end

        # deviate from the defaults specified in the settings definition here
        # to set a default role. The role cannot be specified in the definition as
        # that would mean to know the ID upfront.
        settings['new_project_user_role_id'] = Role.find_by(name: I18n.t(:default_role_project_admin)).try(:id)

        # Set the closed status for repository commit references
        settings['commit_fix_status_id'] = Status.find_by(name: I18n.t(:default_status_closed)).try(:id)

        settings.compact
      end
    end

    private

    def seedable_setting_definitions
      Setting.definitions
             .select(&:writable?)
             .reject { |definition| definition.value.nil? }
    end

    def settings_in_db
      Setting.all.pluck(:name)
    end

    def settings_not_in_db
      data.keys - settings_in_db
    end
  end
end
