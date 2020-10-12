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

class Authorization::AbstractQuery
  class_attribute :model
  class_attribute :base_table

  def self.query(*args)
    arel = transformed_query(*args)

    model.unscoped
         .joins(joins(arel))
         .where(wheres(arel))
         .distinct
  end

  def self.base_query
    Arel::SelectManager
      .new(nil)
      .from(base_table || model.arel_table)
  end

  def self.transformed_query(*args)
    run_transformations(*args)
  end

  class_attribute :transformations

  self.transformations = ::Authorization::QueryTransformations.new

  def self.inherited(subclass)
    subclass.transformations = transformations.copy
  end

  def self.run_transformations(*args)
    query = base_query

    transformator = Authorization::QueryTransformationVisitor.new(transformations: transformations,
                                                                  args: args)

    transformator.accept(query)

    query
  end

  def self.wheres(arel)
    arel.ast.cores.last.wheres.last
  end

  def self.joins(arel)
    arel.join_sources
  end
end
