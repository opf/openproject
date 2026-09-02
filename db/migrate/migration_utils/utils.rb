# frozen_string_literal: true

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

module Migration
  module Utils
    UpdateResult = Struct.new(:row, :updated)

    def say_with_time_silently(message, &)
      say_with_time message do
        suppress_messages(&)
      end
    end

    def in_configurable_batches(klass, default_batch_size: 1000)
      batches = ENV["OPENPROJECT_MIGRATION_BATCH_SIZE"]&.to_i || default_batch_size

      yield klass.in_batches(of: batches)
    end

    def remove_index_if_exists(table_name, index_name)
      remove_index_on(table_name, index_name)
    end

    # Searches a live index name in this order
    # 1. canonical name,
    # 2. pgloader's idx_<oid>_ prefix,
    # 3. (when given) the same columns under a pre-squash migration name.
    def resolved_index_name(table_name, index_name, columns = nil)
      index_name = index_name.to_s
      table_indexes = indexes(table_name)
      actual = table_indexes.find { |index| index.name == index_name || index.name.end_with?("_#{index_name}") }
      actual ||= table_indexes.find { |index| index.columns == Array(columns).map(&:to_s) } unless columns.nil?
      actual&.name
    end

    def remove_index_on(table_name, index_name, columns = nil)
      actual_name = resolved_index_name(table_name, index_name, columns)
      remove_index table_name, name: actual_name if actual_name
    end

    def rename_index_on(table_name, index_name, new_name, columns = nil)
      actual_name = resolved_index_name(table_name, index_name, columns)
      rename_index table_name, actual_name, new_name if actual_name
    end

    ##
    # Executes the given SQL query while passing in sanitized parameters.
    #
    # @param query [String] SQL query including parameter references like `:param`
    # @param params [Hash] Hash containing values for referenced parameters
    #
    # @raise [ActiveRecord::ActiveRecordError] If the query fails
    # @return [PG::Result]
    #
    # Example:
    #
    #   execute_sql "select id from users where mail = :email", email: params[:email]
    #
    def execute_sql(query, params = {})
      query = ActiveRecord::Base.sanitize_sql [query, params]

      ActiveRecord::Base.connection.execute query
    end
  end
end
