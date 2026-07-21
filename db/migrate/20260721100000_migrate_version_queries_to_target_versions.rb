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

class MigrateVersionQueriesToTargetVersions < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Rewriting version queries and board widget filters to target_versions" do
      # Apply every rewrite atomically, even if the per-migration
      # transaction is ever disabled.
      ActiveRecord::Base.transaction do
        rewrite_filters + rewrite_columns + rewrite_sort_criteria + rewrite_group_by + rewrite_widget_filters
      end
    end
  end

  def down
    # Irreversible
  end

  private

  def rewrite_filters
    ActiveRecord::Base.connection.exec_update(<<~SQL.squish)
      UPDATE queries
      SET filters = regexp_replace(filters, '(^|\\n)(:?)version_id:', '\\1\\2target_version_id:', 'g')
      WHERE filters ~ '(^|\\n):?version_id:'
    SQL
  end

  def rewrite_columns
    ActiveRecord::Base.connection.exec_update(<<~SQL.squish)
      UPDATE queries
      SET column_names = replace(column_names, '- :version' || chr(10), '- :target_versions' || chr(10))
      WHERE column_names LIKE '%- :version' || chr(10) || '%'
    SQL
  end

  def rewrite_sort_criteria
    ActiveRecord::Base.connection.exec_update(<<~SQL.squish)
      UPDATE queries
      SET sort_criteria = replace(sort_criteria, '- - version' || chr(10), '- - target_versions' || chr(10))
      WHERE sort_criteria LIKE '%- - version' || chr(10) || '%'
    SQL
  end

  def rewrite_group_by
    ActiveRecord::Base.connection.exec_update(<<~SQL.squish)
      UPDATE queries SET group_by = 'target_versions' WHERE group_by = 'version'
    SQL
  end

  def rewrite_widget_filters
    ActiveRecord::Base.connection.exec_update(<<~SQL.squish)
      UPDATE grid_widgets
      SET options = replace(replace(options, ':version_id:', ':target_version_id:'), '- version:', '- targetVersion:')
      WHERE options LIKE '%:version_id:%' OR options LIKE '%- version:%'
    SQL
  end
end
