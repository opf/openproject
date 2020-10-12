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

module Queries::WorkPackages::Filter::FilterForWpMixin
  def type
    :list
  end

  def allowed_values
    raise NotImplementedError, 'There would be too many candidates'
  end

  def value_objects
    objects = visible_scope.find(no_templated_values)

    if has_templated_value?
      objects << ::Queries::Filters::TemplatedValue.new(WorkPackage)
    end

    objects
  end

  def allowed_objects
    raise NotImplementedError, 'There would be too many candidates'
  end

  def available?
    key = 'Queries::WorkPackages::Filter::FilterForWpMixin/available'

    RequestStore.fetch(key) do
      visible_scope.exists?
    end
  end

  def ar_object_filter?
    true
  end

  def allowed_values_subset
    id_values = visible_scope.where(id: no_templated_values).pluck(:id).map(&:to_s)

    if has_templated_value?
      id_values + templated_value_keys
    else
      id_values
    end
  end

  private

  def visible_scope
    if context.project
      WorkPackage
        .visible
        .for_projects(context.project.self_and_descendants)
    else
      WorkPackage.visible
    end
  end

  def type_strategy
    @type_strategy ||= Queries::Filters::Strategies::HugeList.new(self)
  end

  def no_templated_values
    values.reject { |v| templated_value_keys.include? v }
  end

  def templated_value_keys
    [templated_value_key, deprecated_templated_value_key]
  end

  def templated_value_key
    ::Queries::Filters::TemplatedValue::KEY
  end

  def deprecated_templated_value_key
    ::Queries::Filters::TemplatedValue::DEPRECATED_KEY
  end

  def has_templated_value?
    (values & templated_value_keys).any?
  end
end
