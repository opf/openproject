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

class Queries::WorkPackages::Filter::CommentFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::WorkPackages::Filter::TextFilterOnJoinMixin

  def type
    :text
  end

  private

  def where_condition
    <<-SQL
     SELECT 1 FROM #{journal_table}
     WHERE #{journal_table}.journable_id = #{WorkPackage.table_name}.id
	   AND #{journal_table}.journable_type = '#{WorkPackage.name}'
     AND #{notes_condition}
    SQL
  end

  def notes_condition
    Queries::Operators::Contains.sql_for_field(values, journal_table, "notes")
  end

  def journal_table
    Journal.table_name
  end
end
