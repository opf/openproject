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

module OpenProject
  ##
  # Provides helpers from ActiveRecord::Sanitization
  # outside model context
  module SqlSanitization
    include ::ActiveRecord::Sanitization

    def self.connection
      ::ActiveRecord::Base.connection
    end

    ##
    # Shorthand for:
    # sanitize_sql_array [str, :param0, param1]
    # sanitize_sql_array [str, param0: foo, param1: bar]
    def self.sanitize(sql, *args)
      sanitize_sql_array [sql, *args]
    end

    ##
    # Quoted, escaped input for LIKE/ILIKE statements
    def self.quoted_sanitized_sql_like(input)
      connection.quote_string ActiveRecord::Base.sanitize_sql_like(input)
    end
  end
end
