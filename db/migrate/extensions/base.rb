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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Extensions; end

class Extensions::Base
  class << self
    def extension(name)
      @extension = name
    end

    def creation_sql(sql = nil)
      if sql
        @creation_sql = sql
      else
        @creation_sql ||= <<~SQL.squish
          CREATE EXTENSION IF NOT EXISTS #{@extension} WITH SCHEMA pg_catalog;
        SQL
      end
    end

    def module_text(text = nil)
      if text
        @module_text = text
      else
        @module_text ||= <<~MESSAGE

          \e[33mWARNING:\e[0m Could not find the `#{@extension}` extension for PostgreSQL.
          Please install the postgresql-contrib module for your PostgreSQL installation and re-run the migrations.

        MESSAGE
      end
    end

    def create(migration)
      migration.execute(creation_sql)
    rescue StandardError => e
      raise unless e.message.include?(@extension)

      abort module_text
    end
  end
end
