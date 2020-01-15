#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
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
      !settings_not_in_db.empty?
    end

    def not_applicable_message
      'Skipping settings as all settings already exist in the db'
    end

    def data
      @settings ||= begin
        settings = Setting.available_settings.each_with_object({}) do |(k, v), hash|
          hash[k] = v['default'] || ''
        end

        # deviate from the defaults specified in settings.yml here
        # to set a default role. The role cannot be specified in the settings.yml as
        # that would mean to know the ID upfront.
        update_unless_present(settings, 'new_project_user_role_id') do
          Role.find_by(name: I18n.t(:default_role_project_admin)).try(:id)
        end

        # Set the closed status for repository commit references
        update_unless_present(settings, 'commit_fix_status_id') do
          Status.find_by(name: I18n.t(:default_status_closed)).try(:id)
        end

        settings
      end
    end

    private

    def update_unless_present(settings, key)
      if !settings_in_db.include?(key)
        value = yield
        settings[key] = value unless value.nil?
      end
    end

    def settings_in_db
      @settings_in_db ||= Setting.all.pluck(:name)
    end

    def settings_not_in_db
      data.keys - settings_in_db
    end
  end
end
