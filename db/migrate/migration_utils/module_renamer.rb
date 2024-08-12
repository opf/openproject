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

module Migration
  module MigrationUtils
    class ModuleRenamer
      class << self
        def add_to_enabled(new_module, old_modules)
          execute <<~SQL
            INSERT INTO
              enabled_modules (
                project_id,
                name
              )
            SELECT
              DISTINCT(project_id),
              '#{new_module}'
            FROM
              enabled_modules
            WHERE
              name IN (#{comma_separated_strings(old_modules)})
          SQL
        end

        def remove_from_enabled(modules)
          execute <<~SQL
            DELETE FROM
              enabled_modules
            WHERE
              name IN (#{comma_separated_strings(modules)})
          SQL
        end

        def add_to_default(new_modules, old_modules)
          # avoid creating the settings implicitly on new installations
          setting = Setting.find_by(name: "default_projects_modules")

          return unless setting

          cleaned_setting = setting.value - Array(old_modules)

          if setting.value != cleaned_setting
            Setting.default_projects_modules = cleaned_setting + Array(new_modules)
          end
        end

        def remove_from_default(name)
          add_to_default([], name)
        end

        private

        def execute(string)
          ActiveRecord::Base.connection.execute string
        end

        def comma_separated_strings(array)
          Array(array).map { |i| "'#{i}'" }.join(", ")
        end
      end
    end
  end
end
