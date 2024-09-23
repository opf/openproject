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

class Report::GroupBy
  class Base < Report::Chainable
    include Report::QueryUtils

    inherited_attributes :group_fields, list: true, merge: false

    def correct_position?
      type == :row or !child.is_a?(Report::GroupBy::Base) or child.type == :column
    end

    def filter?
      false
    end

    def sql_aggregation?
      child.filter?
    end

    def cache_key
      self.class.cache_key + type.to_s[0, 1]
    end

    ##
    # @param [FalseClass, TrueClass] prefix Whether or not add a table prefix the field names
    # @return [Array<String,Symbol>] List of group by fields corresponding to self and all parents'
    def all_group_fields(prefix = true)
      @all_group_fields ||= []
      @all_group_fields[prefix ? 0 : 1] ||= begin
        fields = group_fields.reject { |c| c.blank? or c == "base" }
        (parent ? parent.all_group_fields(prefix) : []) + (prefix ? with_table(fields) : fields)
      end.uniq
    end

    def self.select_fields(*fields)
      unless fields.empty?
        @select_fields ||= []
        @select_fields += fields
      end
      @select_fields
    end

    def select_fields
      # + (parent ? parent.select_fields : [])
      self.class.select_fields || group_fields
    end

    ##
    # @param [FalseClass, TrueClass] prefix Whether or not add a table prefix the field names
    # @return [Array<String,Symbol>] List of select fields corresponding to self and all parents'
    def all_select_fields(prefix = true)
      @all_select_fields ||= []
      @all_select_fields[prefix ? 0 : 1] ||= begin
        fields = select_fields.reject { |c| c.blank? or c == "base" }
        (parent ? parent.all_select_fields(prefix) : []) + (prefix ? with_table(fields) : fields)
      end.uniq
    end

    def clear
      @all_group_fields = @all_select_fields = nil
      super
    end

    def aggregation_mixin
      sql_aggregation? ? engine::GroupBy::SqlAggregation : engine::GroupBy::RubyAggregation
    end

    def initialize(child = nil, options = {})
      super
      extend aggregation_mixin
      group_fields field
    end

    def result
      super
    end

    def compute_result
      super.tap do |r|
        r.type = type
        r.important_fields = group_fields
      end
    end

    def define_group(sql)
      sql.select all_select_fields
      sql.group_by all_group_fields(true)
    end
  end
end
