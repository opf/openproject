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
  class SettingSeeder < Seeder
    self.needs = [
      BasicData::ProjectRoleSeeder,
      BasicData::GlobalRoleSeeder,
      BasicData::StatusSeeder
    ]

    def seed_data!
      Setting.transaction do
        settings_not_in_db.each do |setting_name|
          datum = data[setting_name]

          Setting[setting_name.to_sym] = datum
        end
        force_default_language_setting
      end
    end

    def applicable?
      settings_not_in_db.any?
    end

    def not_applicable_message
      "Skipping settings as all settings already exist in the db"
    end

    def data
      @data ||= begin
        settings = seedable_setting_definitions.each_with_object({}) do |definition, hash|
          hash[definition.name] = definition.value
        end

        # deviate from the defaults specified in the settings definition here
        # to set a default role. The role cannot be specified in the definition as
        # that would mean to know the ID upfront.
        new_project_user_role_id = seed_data.find_reference(:default_role_project_admin, default: nil).try(:id)
        settings["new_project_user_role_id"] = new_project_user_role_id

        # Set the closed status for repository commit references
        status_closed = seed_data.find_reference(:default_status_closed, default: nil)
        settings["commit_fix_status_id"] = status_closed.try(:id)

        # Add the current locale to the list of available languages
        settings["available_languages"] = (Setting.available_languages + [I18n.locale.to_s]).uniq.sort

        settings.compact
      end
    end

    private

    # Set the default language to the current locale
    def force_default_language_setting
      default_language_setting = Setting.find_or_initialize_by(name: "default_language")
      # Need to force the value because it's non-writable if
      # OPENPROJECT_DEFAULT_LANGUAGE env var is set.
      default_language_setting.set_value!(I18n.locale, force: true)
      default_language_setting.save!
    end

    def seedable_setting_definitions
      Settings::Definition
        .all
        .values
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
