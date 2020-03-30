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

class ::Query::SortCriteria < ::SortHelper::SortCriteria
  attr_reader :available_columns

  ##
  # Initialize the sort criteria with the set of columns
  def initialize(available_columns)
    super()
    @available_columns = available_columns
  end

  ##
  # Building the query sort criteria needs to respect
  # specific options of the column
  def to_a
    @criteria
      .map { |attribute, order| [find_column(attribute), @available_criteria[attribute], order] }
      .reject { |column, criterion, _| column.nil? || criterion.nil? }
      .map { |column, criterion, order| [column, execute_criterion(criterion), order] }
      .map { |column, criterion, order| append_order(column, Array(criterion), order) }
      .compact
  end

  private

  ##
  # Find the matching column for the attribute
  def find_column(attribute)
    available_columns.detect { |column| column.name.to_s == attribute.to_s }
  end

  ##
  # append the order to the criteria
  # as well as any order handling by the column itself
  def append_order(column, criterion, asc = true)
    ordered_criterion = append_direction(criterion, asc)

    ordered_criterion.map { |statement| "#{statement} #{column.null_handling(asc)}" }
  end

  def execute_criterion(criteria)
    Array(criteria).map do |criterion|
      if criterion.respond_to?(:call)
        criterion.call
      else
        criterion
      end
    end
  end
end
