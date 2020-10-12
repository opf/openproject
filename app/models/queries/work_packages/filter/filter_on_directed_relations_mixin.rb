#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Queries::WorkPackages::Filter::FilterOnDirectedRelationsMixin
  include ::Queries::WorkPackages::Filter::FilterForWpMixin

  def where
    # The order in which we call the methods on `Relation` matters, as
    # the `Relation`'s association `includes` is overwritten with the method `includes`
    # otherwise.
    relations_subselect = Relation
                          .send(normalized_relation_type)
                          .direct
                          .where(relation_filter)
                          .select(relation_select)

    operator = if operator_class == Queries::Operators::Equals
                 'IN'
               else
                 'NOT IN'
               end

    "#{WorkPackage.table_name}.id #{operator} (#{relations_subselect.to_sql})"
  end

  def relation_type
    raise NotImplementedError
  end

  def normalized_relation_type
    ::Relation.canonical_type relation_type
  end

  private

  def relation_filter
    raise NotImplementedError
  end

  def relation_select
    raise NotImplementedError
  end
end
