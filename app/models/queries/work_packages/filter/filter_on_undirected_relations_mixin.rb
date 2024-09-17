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

module Queries::WorkPackages::Filter::FilterOnUndirectedRelationsMixin
  include ::Queries::WorkPackages::Filter::FilterForWpMixin

  def where
    operator, junction = operator_and_junction

    <<-SQL
      #{WorkPackage.table_name}.id #{operator} (#{relations_subselect_from_to.to_sql})
      #{junction}
      #{WorkPackage.table_name}.id #{operator} (#{relations_subselect_to_from.to_sql})
    SQL
  end

  def relation_type
    raise NotImplementedError
  end

  private

  def operator_and_junction
    if operator_class <= Queries::Operators::Equals
      %w[IN OR]
    else
      ["NOT IN", "AND"]
    end
  end

  def relations_subselect_to_from
    relation_subselect
      .where(to_id: values)
      .select(:from_id)
  end

  def relations_subselect_from_to
    relation_subselect
      .where(from_id: values)
      .select(:to_id)
  end

  def relation_subselect
    Relation
      .where(relation_type:)
  end
end
