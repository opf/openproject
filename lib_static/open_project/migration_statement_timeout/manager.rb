# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module MigrationStatementTimeout
  module Manager
    class SetMinimumStatementTimeout
      attr_reader :conn

      def initialize(conn, migration)
        @conn = conn
        @migration = migration
      end

      delegate :say, to: :@migration

      def call(min_timeout)
        if same_timeout?(min_timeout)
          say "ignore set statement_timeout to #{min_timeout}: " \
              "current statement timeout is already #{current_timeout}"
        elsif current_timeout_disabled?
          say "ignore set statement_timeout to #{min_timeout}: " \
              "current statement timeout is disabled (value is 0)"
        elsif current_timeout_is_greater_than?(min_timeout)
          say "ignore set statement_timeout to #{min_timeout}: " \
              "current statement timeout #{current_timeout} is greater"
        else
          set_timeout(min_timeout)
          say "set statement_timeout to #{min_timeout} (was #{current_timeout} before)"
        end
      end

      def current_timeout_disabled?
        in_ms(current_timeout).zero?
      end

      def same_timeout?(min_timeout)
        in_ms(current_timeout) == in_ms(min_timeout)
      end

      def current_timeout_is_greater_than?(min_timeout)
        in_ms(min_timeout).positive? && in_ms(current_timeout) > in_ms(min_timeout)
      end

      def current_timeout
        @current_timeout ||= get_timeout
      end

      def get_timeout
        conn.execute('SHOW statement_timeout').first['statement_timeout']
      end

      def set_timeout(timeout)
        conn.execute("SET LOCAL statement_timeout = '#{timeout}'")
      end

      def in_ms(timeout)
        case timeout
        when Integer
          timeout
        when /\A\d+(ms)?\z/
          timeout.to_i
        when /\A\d+s\z/
          timeout.to_i * 1000
        when /\A\d+min\z/
          timeout.to_i * 1000 * 60
        when /\A\d+h\z/
          timeout.to_i * 1000 * 60 * 60
        else
          raise ArgumentError, "Unrecognized statement timeout duration #{timeout.inspect}"
        end
      end
    end

    def exec_migration(conn, direction)
      min_timeout = self.class.minimum_statement_timeout
      return super unless min_timeout
      return super unless direction == :up

      if disable_ddl_transaction
        raise 'Cannot set local statement_timeout outside of a transaction. ' \
              'Try removing disable_ddl_transaction! from your migration.'
      end

      SetMinimumStatementTimeout.new(conn, self).call(min_timeout)

      super
    end
  end
end
