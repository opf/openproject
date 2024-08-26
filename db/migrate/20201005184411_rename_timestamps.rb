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

class RenameTimestamps < ActiveRecord::Migration[6.0]
  def change
    alter_name_and_defaults(:comments, :created_on, :created_at)
    alter_name_and_defaults(:comments, :updated_on, :updated_at)

    alter_name_and_defaults(:messages, :created_on, :created_at)
    alter_name_and_defaults(:messages, :updated_on, :updated_at)

    alter_name_and_defaults(:versions, :created_on, :created_at)
    alter_name_and_defaults(:versions, :updated_on, :updated_at)

    alter_name_and_defaults(:users, :created_on, :created_at)
    alter_name_and_defaults(:users, :updated_on, :updated_at)

    alter_name_and_defaults(:wiki_pages, :created_on, :created_at)
    alter_name_and_defaults(:wiki_redirects, :created_on, :created_at)

    alter_name_and_defaults(:tokens, :created_on, :created_at)

    alter_name_and_defaults(:settings, :updated_on, :updated_at)

    alter_name_and_defaults(:cost_queries, :created_on, :created_at)
    alter_name_and_defaults(:cost_queries, :updated_on, :updated_at)

    alter_name_and_defaults(:wiki_contents, :updated_on, :updated_at)

    add_timestamp_column(:journals, :updated_at, :created_at)

    add_timestamp_column(:roles, :created_at, "CURRENT_TIMESTAMP")
    add_timestamp_column(:roles, :updated_at, "CURRENT_TIMESTAMP")
  end

  private

  def alter_name_and_defaults(table, old_column_name, new_column_name)
    rename_column table, old_column_name, new_column_name

    change_column_default table, new_column_name, from: nil, to: -> { "CURRENT_TIMESTAMP" }

    # Ensure we reset column information because otherwise,
    # +updated_on+ will still be used.
    begin
      cls = table.to_s.singularize.classify.constantize
      cls.reset_column_information
    rescue StandardError => e
      warn "Could not reset_column_information for table #{table}: #{e.message}"
    end
  end

  def add_timestamp_column(table, column_name, from_column = nil)
    add_column table, column_name, :timestamp, default: -> { "CURRENT_TIMESTAMP" }

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE
            #{table}
          SET #{column_name} = #{from_column}
        SQL
      end
    end

    change_column_null table, column_name, true
  end
end
