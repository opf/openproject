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

# encoding: UTF-8

class Report::Table
  attr_accessor :query
  include Report::QueryUtils

  def initialize(query)
    @query = query
  end

  def row_index
    get_index :row
  end

  def column_index
    get_index :column
  end

  def row_fields
    fields_for :row
  end

  def column_fields
    fields_for :column
  end

  def rows_for(result)
    fields_for result, :row
  end

  def columns_for(result)
    fields_for result, :column
  end

  def fields_from(result, type)
    fields_for(type).map { |k| map_field k, result.fields[k] }
  end

  ##
  # @param [Array] expected Fields expected
  # @param [Array,Hash,Result] given Fields/result to be tested
  # @return [TrueClass,FalseClass]
  def satisfies?(type, expected, given)
    given  = fields_from(given, type) if given.respond_to? :to_hash
    zipped = expected.zip given
    zipped.all? { |a, b| a == b or b.nil? }
  end

  def fields_for(type)
    @fields_for ||= begin
                      child = query.chain
                      fields = Hash.new { |h, k| h[k] = [] }

                      until child.filter?
                        fields[child.type].push(*child.group_fields)
                        child = child.child
                      end
                      fields
                    end

    @fields_for[type]
  end

  def get_row(*args)
    @query.each_row { |result| return with_gaps_for(type, result) if satisfies? :row, args, result }
    []
  end

  def with_gaps_for(type, result)
    return enum_for(:with_gaps_for, type, result) unless block_given?

    stack = get_index(type).dup
    result.each_direct_result do |subresult|
      yield nil until stack.empty? or satisfies? type, stack.shift, subresult
      yield subresult
    end
    stack.size.times { yield nil }
  end

  def [](x, y)
    get_row(row_index[y]).first(x).last
  end

  def get_index(type)
    @indexes ||= begin
      indexes = Hash.new { |h, k| h[k] = Set.new }
      query.each_direct_result { |result| [:row, :column].each { |t| indexes[t] << fields_from(result, t) } }
      indexes.keys.each { |k| indexes[k] = indexes[k].sort { |x, y| compare x, y } }
      indexes
    end
    @indexes[type]
  end
end
