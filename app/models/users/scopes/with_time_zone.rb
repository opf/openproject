#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

# Find a user account by matching case-insensitive.
module Users::Scopes
  module WithTimeZone
    extend ActiveSupport::Concern

    class_methods do
      def with_time_zone(time_zones)
        return User.none if time_zones.empty?

        where_clause = <<~SQL.squish
          COALESCE(
            NULLIF(user_preferences.settings->>'time_zone', ''),
            #{user_default_time_zone.to_sql}
          ) IN (?)
        SQL
        User
          .left_joins(:preference)
          .where(where_clause, time_zones)
      end

      def user_default_time_zone
        Arel::Nodes::build_quoted(Setting.user_default_timezone.presence || 'Etc/UTC')
      end
    end
  end
end
