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

class Queries::WorkPackages::Columns::CustomFieldColumn < Queries::WorkPackages::Columns::WorkPackageColumn
  def initialize(custom_field)
    super

    set_name! custom_field
    set_sortable! custom_field
    set_groupable! custom_field
    set_summable! custom_field

    @cf = custom_field
  end

  def set_name!(custom_field)
    self.name = "cf_#{custom_field.id}".to_sym
  end

  def set_sortable!(custom_field)
    self.sortable = custom_field.order_statements || false
  end

  def set_groupable!(custom_field)
    self.groupable = custom_field.group_by_statements if groupable_custom_field?(custom_field)
    self.groupable ||= false
  end

  def set_summable!(custom_field)
    self.summable = %w(float int).include?(custom_field.field_format)
  end

  def groupable_custom_field?(custom_field)
    %w(list date bool int).include?(custom_field.field_format)
  end

  def caption
    @cf.name
  end

  def null_handling(asc)
    custom_field.null_handling(asc)
  end

  def custom_field
    @cf
  end

  def value(work_package)
    work_package.formatted_custom_value_for(@cf.id)
  end

  def sum_of(work_packages)
    if work_packages.respond_to?(:joins)
      cast = @cf.field_format == 'int' ? 'BIGINT' : 'FLOAT'

      CustomValue
        .where(customized: work_packages, custom_field: @cf)
        .where.not(value: nil)
        .where.not(value: '')
        .pluck("SUM(value::#{cast})")
        .first
    else
      # TODO: eliminate calls of this method with an Array and drop the :compact call below
      ActiveSupport::Deprecation.warn('Passing an array of work packages is deprecated. Pass an AR-relation instead.')
      work_packages.map { |wp| wp.typed_custom_value_for(@cf) }.compact.reduce(:+)
    end
  end

  def self.instances(context = nil)
    if context
      context.all_work_package_custom_fields
    else
      WorkPackageCustomField.all
    end
      .reject { |cf| cf.field_format == 'text' }
      .map { |cf| new(cf) }
  end
end
