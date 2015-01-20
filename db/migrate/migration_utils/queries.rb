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

require 'yaml'

require_relative 'utils'

module Migration
  module Utils
    def update_query_references_with_keys(keys)
      update_column_values('queries', COLUMNS.keys, update_query_reference(keys, COLUMNS), nil)
    end

    private

    COLUMNS = {
      'filters' => { is_text_column: false },
      'column_names' => { is_text_column: false },
      'sort_criteria' => { is_text_column: false },
      'group_by' => { is_text_column: true }
    }

    def update_query_reference(keys, columns)
      Proc.new do |row|
        columns.keys.each do |column|
          unless row[column].nil?
            if columns[column][:is_text_column]
              process_text_data(row, column, keys)
            else
              row[column] = process_yaml_data(row, column, keys)
            end
          end
        end

        UpdateResult.new(row, true)
      end
    end

    def process_yaml_data(row, column, keys)
      return row[column] if row[column].blank?

      value = YAML.load row[column]

      if value.is_a? Array
        value.map! do |e|
          if e.is_a? Array
            e.map! { |v| keys.has_key?(v) ? keys[v] : v }
          else
            keys.has_key?(e.to_s) ? keys[e.to_s].to_sym : e
          end
        end
      elsif value.is_a? Hash
        keys.select { |k| value[k.to_s] }
          .each_pair { |k, v| value[v] = value.delete k }
      end

      YAML.dump value
    end

    def process_text_data(row, column, keys)
      value = row[column]

      keys.each_key do |k|
        regex = Regexp.new(k)
        replace = keys[k]

        value.gsub!(regex, replace)
      end

      value
    end
  end
end
