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

class Queries::WorkPackages::Selects::WorkPackageSelect
  attr_reader :highlightable,
              :name,
              :sortable_join,
              :groupable_join,
              :groupable_select,
              :summable,
              :default_order,
              :association,
              :null_handling,
              :summable_select,
              :summable_work_packages_select

  def self.instances(_context = nil)
    new
  end

  def self.select_group_by(group_by_statement)
    group_by = group_by_statement
    group_by = group_by.first if group_by.is_a?(Array)

    "#{group_by} group_id"
  end

  def self.scoped_column_sum(scope, select, grouped:, query:)
    scope = scope.except(:order, :select)

    if grouped
      scope
        .joins(query.group_by_join_statement)
        .group(query.group_by_statement)
        .select(select_group_by(query.group_by_select), select)
    else
      scope
        .select(select)
    end
  end

  def sortable_join_statement(_query)
    sortable_join
  end

  def null_handling(_asc)
    @null_handling
  end

  def displayable
    @displayable.nil? ? true : @displayable
  end

  def sortable
    name_or_value_or_false(@sortable)
  end

  def groupable
    name_or_value_or_false(@groupable)
  end

  def displayable? = !!displayable

  def sortable? = !!sortable

  def groupable? = !!groupable

  def highlightable? = !!highlightable

  def summable?
    summable || @summable_select || @summable_work_packages_select
  end

  def summable_select
    @summable_select || name
  end

  def summable_work_packages_select
    if @summable_work_packages_select == false
      nil
    elsif @summable_work_packages_select
      @summable_work_packages_select
    elsif summable&.respond_to?(:call)
      nil
    else
      name
    end
  end

  def value(model)
    model.send name
  end

  def initialize(name, options = {})
    @name = name

    %i[
      sortable
      sortable_join
      displayable
      groupable
      groupable_join
      summable
      summable_select
      summable_work_packages_select
      association
      null_handling
      default_order
    ].each do |attribute|
      instance_variable_set(:"@#{attribute}", options[attribute])
    end

    @highlightable = !!options.fetch(:highlightable, false)
  end

  def caption
    WorkPackage.human_attribute_name(name)
  end

  protected

  def name_or_value_or_false(value)
    # This is different from specifying value = nil in the signature
    # in that it will also set the value to false if nil is provided.
    value ||= false

    # Explicitly checking for true because apparently, we do not want
    # truish values to count here.
    if value == true
      name.to_s
    else
      value
    end
  end
end
