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

class Queries::WorkPackages::Filter::RelatableFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::WorkPackages::Filter::FilterForWpMixin

  def available?
    User.current.allowed_to?(:manage_work_package_relations, nil, global: true)
  end

  def type
    :relation
  end

  def type_strategy
    @type_strategy ||= Queries::Filters::Strategies::Relation.new(self)
  end

  def where
    # all of the filter logic is handled by #scope
    "(1 = 1)"
  end

  def scope
    if operator == Relation::TYPE_RELATES
      relateable_from_or_to
    elsif operator != 'parent' && canonical_operator == operator
      relateable_to
    else
      relateable_from
    end
  end

  private

  def relateable_from_or_to
    relateable_to.or(relateable_from)
  end

  def relateable_from
    WorkPackage.relateable_from(from)
  end

  def relateable_to
    WorkPackage.relateable_to(from)
  end

  def from
    WorkPackage.find(values.first)
  end

  def canonical_operator
    Relation.canonical_type(operator)
  end
end
