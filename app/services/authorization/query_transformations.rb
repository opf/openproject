#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Authorization::QueryTransformations
  def for?(on)
    !!transformations[transformation_key(on)]
  end

  def for(on)
    transformations[transformation_key(on)]
  end

  def register(on,
               name,
               after: [],
               before: [],
               &block)

    transformation = ::Authorization::QueryTransformation.new(on, name, after, before, block)

    add_transformation(transformation)
    sort_transformations(on)
  end

  def copy
    the_new = self.class.new

    the_new.transformations = transformations.deep_dup
    the_new.transformation_order = transformation_order.deep_dup

    the_new
  end

  protected

  attr_accessor :transformations,
                :transformation_order

  private

  def transformation_key(on)
    if on.respond_to?(:to_sql)
      on.to_sql
    else
      on
    end
  end

  def transformations
    @transformations ||= {}
  end

  def transformation_order
    @transformation_order ||= ::Authorization::QueryTransformationsOrder.new
  end

  def add_transformation(transformation)
    transformations[transformation_key(transformation.on)] ||= []

    transformations[transformation_key(transformation.on)] << transformation

    transformation_order << transformation
  end

  def sort_transformations(on)
    desired_order = transformation_order.full_order

    transformations[transformation_key(on)].sort_by! { |x| desired_order.index x.name }
  end
end
