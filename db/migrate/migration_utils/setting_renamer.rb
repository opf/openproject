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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Migration
  module MigrationUtils
    class SettingRenamer
      # define all the following methods as class methods
      class << self
        def rename(source_name, target_name)
          ActiveRecord::Base.connection.execute <<~SQL.squish
            UPDATE #{settings_table}
            SET name = #{quote_value(target_name)}
            WHERE name = #{quote_value(source_name)}
          SQL
        end

        def rename_value(setting_name, from, to)
          ActiveRecord::Base.connection.execute <<~SQL.squish
            UPDATE #{settings_table}
            SET value = #{quote_value(to)}
            WHERE name = #{quote_value(setting_name)} AND value = #{quote_value(from)}
          SQL
        end

        private

        def settings_table
          @settings_table ||= ActiveRecord::Base.connection.quote_table_name("settings")
        end

        def quote_value(value)
          ActiveRecord::Base.connection.quote(value)
        end
      end
    end
  end
end
