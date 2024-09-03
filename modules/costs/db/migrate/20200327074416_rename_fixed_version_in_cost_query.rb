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

class RenameFixedVersionInCostQuery < ActiveRecord::Migration[6.0]
  def up
    rename_query_attributes("FixedVersion", "Version")
  end

  def down
    rename_query_attributes("Version", "FixedVersion")
  end

  def rename_query_attributes(from, to)
    ActiveRecord::Base.connection.exec_query(
      <<-SQL.squish
        UPDATE
          cost_queries q_sink
        SET
          serialized = regexp_replace(q_source.serialized, '(\n- - )#{from}Id(\n)', '\\1#{to}Id\\2')
        FROM
          cost_queries q_source
        WHERE
          q_source.serialized LIKE '%#{from}%'
          AND q_sink.id = q_source.id
    SQL
    )
  end
end
