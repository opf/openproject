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
  module MigrationUtils
    class Column
      attr_reader :connection, :table, :name, :ar_column

      def initialize(connection, table, name)
        @connection = connection
        @table = table
        @name = name
        @ar_column = connection.columns(table.to_s).find { |col| col.name == name.to_s }

        raise ArgumentError, "Column not found: #{name}" if ar_column.nil?
      end

      def change_type!(type)
        return if self.type == type.to_s

        connection.change_column table, name, type

        return if id_seq_name.nil?

        connection.execute <<~SQL.squish
          ALTER SEQUENCE #{id_seq_name} AS #{type};
        SQL
      end

      def id_seq_name
        @id_seq_name ||= connection.serial_sequence table, name
      end

      def type
        ar_column.sql_type.to_s
      end
    end
  end
end
