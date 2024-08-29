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

class RenameFixedVersion < ActiveRecord::Migration[6.0]
  def up
    rename_column :work_packages, :fixed_version_id, :version_id
    rename_column :work_package_journals, :fixed_version_id, :version_id

    rename_query_attributes("fixed_version", "version")
  end

  def down
    rename_column :work_packages, :version_id, :fixed_version_id
    rename_column :work_package_journals, :version_id, :fixed_version_id

    rename_query_attributes("version", "fixed_version")
  end

  def rename_query_attributes(from, to)
    ActiveRecord::Base.connection.exec_query(
      <<-SQL.squish
        UPDATE
          queries q_sink
        SET
          filters = regexp_replace(q_source.filters, '(\n)#{from}_id:(\n)', '\\1#{to}_id:\\2'),
          column_names = regexp_replace(q_source.column_names, ':#{from}', ':#{to}'),
          sort_criteria = regexp_replace(q_source.sort_criteria, '#{from}', '#{to}'),
          group_by = regexp_replace(q_source.group_by, '#{from}', '#{to}')
        FROM
          queries q_source
        WHERE
          (q_source.filters LIKE '%#{from}_id:%'
          OR q_source.column_names LIKE '%#{from}%'
          OR q_source.sort_criteria LIKE '%#{from}%'
          OR q_source.group_by = '#{from}')
          AND q_sink.id = q_source.id
    SQL
    )
  end
end
