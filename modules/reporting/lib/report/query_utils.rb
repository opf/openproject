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

module Report::QueryUtils
  Infinity = 1.0 / 0
  include Engine

  delegate :quoted_false, :quoted_true, to: 'engine.reporting_connection'
  attr_writer :engine

  include Costs::NumberHelper

  ##
  # Graceful string quoting.
  #
  # @param [Object] str String to quote
  # @return [Object] Quoted version
  def quote_string(str)
    return str unless str.respond_to? :to_str
    engine.reporting_connection.quote_string(str)
  end

  def current_language
    ::I18n.locale
  end

  ##
  # Creates a SQL fragment representing a collection/array.
  #
  # @see quote_string
  # @param [#flatten] *values Ruby collection
  # @return [String] SQL collection
  def collection(*values)
    return '' if values.empty?

    v = if values.is_a?(Array)
          values.flatten.each_with_object([]) do |str, l|
            l << split_with_safe_return(str)
          end
        else
          split_with_safe_return(str)
        end

    "(#{v.flatten.map { |x| "'#{quote_string(x)}'" }.join(', ')})"
  end

  def split_with_safe_return(str)
    # From ruby doc:
    # When the input str is empty an empty Array is returned as the string is
    # considered to have no fields to split.
    str.to_s.empty? ? '' : str.to_s.split(',')
  end

  ##
  # Graceful, internationalized quoted string.
  #
  # @see quote_string
  # @param [Object] str String to quote/translate
  # @return [Object] Quoted, translated version
  def quoted_label(ident)
    "'#{quote_string ::I18n.t(ident)}'"
  end

  def quoted_date(date)
    engine.reporting_connection.quoted_date date.to_dateish
  end

  ##
  # SQL date quoting.
  # @param [Date,Time] date Date to quote.
  # @return [String] Quoted date.
  def quote_date(date)
    "'#{quoted_date date}'"
  end

  ##
  # Generate a table name for any object.
  #
  # @example Table names
  #   table_name_for Issue    # => 'issues'
  #   table_name_for :issue   # => 'issues'
  #   table_name_for "issue"  # => 'issues'
  #   table_name_for "issues" # => 'issues
  #
  # @param [#table_name, #to_s] object Object you need the table name for.
  # @return [String] The table name.
  def table_name_for(object)
    return object.table_name if object.respond_to? :table_name
    object.to_s.tableize
  end

  ##
  # Generate a field name
  #
  # @example Field names
  #   field_name_for nil                            # => 'NULL'
  #   field_name_for 'foo'                          # => 'foo'
  #   field_name_for [Issue, 'project_id']          # => 'issues.project_id'
  #   field_name_for [:issue, 'project_id'], :entry # => 'issues.project_id'
  #   field_name_for 'project_id', :entry           # => 'entries.project_id'
  #
  # @param [Array, Object] arg Object to generate field name for.
  # @param [Object, optional] default_table Table name to use if no table name is given.
  # @return [String] Field name.
  def field_name_for(arg, default_table = nil)
    return 'NULL' unless arg
    return field_name_for(arg.keys.first, default_table) if arg.is_a? Hash
    return arg if arg.is_a? String and arg =~ /\.| |\(.*\)/
    return table_name_for(arg.first || default_table) + '.' << arg.last.to_s if arg.is_a? Array and arg.size == 2
    return arg.to_s unless default_table
    field_name_for [default_table, arg]
  end

  ##
  # Sanitizes sql condition
  #
  # @see ActiveRecord::Base#sanitize_sql_for_conditions
  # @param [Object] statement Not sanitized statement.
  # @return [String] Sanitized statement.
  def sanitize_sql_for_conditions(statement)
    engine.send :sanitize_sql_for_conditions, statement
  end

  ##
  # Generates a SQL case statement.
  #
  # @example
  #   switch "#{table}.overridden_costs IS NULL" => [model, :costs], :else => [model, :overridden_costs]
  #
  # @param [Hash] options Condition => Result.
  # @return [String] Case statement.
  def switch(options)
    desc = "#{__method__} #{options.inspect[1..-2]}".gsub(/(Cost|Time)Entry\([^\)]*\)/, '\1Entry')
    options = options.with_indifferent_access
    else_part = options.delete :else
    "-- #{desc}\n\t" \
    "CASE #{options.map { |k, v|
      "\n\t\tWHEN #{field_name_for k}\n\t\t" \
    "THEN #{field_name_for v}"
    }.join(', ')}\n\t\tELSE #{field_name_for else_part}\n\tEND"
  end

  ##
  # Converts value with a given behavior, but treats nil differently.
  # Params
  #  - value: the value to convert
  #  - block (optional) - defines how to convert values which are not nil
  #               if no block is given, values stay untouched
  def convert_unless_nil(value)
    if value.nil?
      1.0 / 0 # Infinity, which is greater than any string or number
    else
      yield value
    end
  end

  def map_field(key, value)
    case key.to_s
    when 'tweek', 'tmonth', 'tweek' then value.to_i
    else convert_unless_nil(value, &:to_s)
    end
  end

  def adapter_name
    engine.reporting_connection.adapter_name.downcase.to_sym
  end

  def cache
    Report::QueryUtils.cache
  end

  def compare(first, second)
    first  = Array(first).flatten
    second = Array(second).flatten
    first.zip second do |a, b|
      return (a <=> b) || (a == Infinity ? 1 : -1) if a != b
    end
    second.size > first.size ? -1 : 0
  end

  def typed(type, value, escape = true)
    safe_value = escape ? "'#{quote_string value}'" : value
    "#{safe_value}::#{type}"
  end

  def iso_year_week(field, default_table = nil)
    field_name = field_name_for(field, default_table)

    "(EXTRACT(isoyear from #{field_name})*100 + \n\t\t" \
    "EXTRACT(week from #{field_name} - \n\t\t" \
    "(EXTRACT(dow FROM #{field_name})::int+6)%7))"
  end

  def self.cache
    @cache ||= Hash.new { |h, k| h[k] = {} }
  end

  def self.included(klass)
    super
    klass.extend self
  end
end
