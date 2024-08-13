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

class Queries::WorkPackages::Filter::TypeaheadFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def type
    :search
  end

  def where
    parts = values.map(&:split).flatten

    parts.map do |part|
      conditions = [subject_condition(part),
                    project_name_condition(part)]

      if (match = part.match(/^#?(\d+)$/))
        conditions << id_condition(match[1])
      end

      "(#{conditions.join(' OR ')})"
    end.join(" AND ")
  end

  def subject_condition(string)
    Queries::Operators::Contains.sql_for_field([string], WorkPackage.table_name, "subject")
  end

  def project_name_condition(string)
    Queries::Operators::Contains.sql_for_field([string], Project.table_name, "name")
  end

  def id_condition(string)
    "#{WorkPackage.table_name}.id::varchar(20) LIKE '%#{string}%'"
  end
end
