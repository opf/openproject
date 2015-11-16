#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
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
      Setting.available_settings.each_with_object({}) do |(k, v), hash|
        hash[k] = v['default'] || ''
      end
    end

    private

    def settings_in_db
      Setting.all.pluck(:name)
    end

    def settings_not_in_db
      data.keys - settings_in_db
    end
  end
end
