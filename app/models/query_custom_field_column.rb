#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class QueryCustomFieldColumn < QueryColumn
  def initialize(custom_field)
    self.name = "cf_#{custom_field.id}".to_sym
    self.sortable = custom_field.order_statements || false
    if %w(list date bool int).include?(custom_field.field_format)
      self.groupable = custom_field.order_statements
    end
    self.groupable ||= false
    self.summable = %w(float int).include?(custom_field.field_format)

    @cf = custom_field
  end

  def caption
    @cf.name
  end

  def custom_field
    @cf
  end

  def value(work_package)
    cv = work_package.custom_values.detect { |value| value.custom_field_id == @cf.id }
    cv && cv.typed_value
  end

  def sum_of(work_packages)
    if work_packages.respond_to?(:joins)
      # we can't perform the aggregation on the SQL side. Try to filter useless rows to reduce work.
      work_packages = work_packages
                      .joins(:custom_values)
                      .where(custom_values: { custom_field: @cf })
                      .where("#{CustomValue.table_name}.value IS NOT NULL")
                      .where("#{CustomValue.table_name}.value != ''")
    end

    # TODO: eliminate calls of this method with an Array and drop the :compact call below
    work_packages.map { |wp| value(wp) }.compact.reduce(:+)
  end
end
