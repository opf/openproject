#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Migration
  module DbWorker
    def quote_value(name)
      ActiveRecord::Base.connection.quote name
    end

    def quoted_table_name(name)
      ActiveRecord::Base.connection.quote_table_name name
    end

    def db_table_exists?(name)
      ActiveRecord::Base.connection.table_exists? name
    end

    def db_column(name)
      ActiveRecord::Base.connection.quote_column_name(name)
    end

    def db_columns(table_name)
      ActiveRecord::Base.connection.columns table_name
    end

    def db_select_all(statement)
      ActiveRecord::Base.connection.select_all(statement).to_a
    end

    def db_execute(statement)
      ActiveRecord::Base.connection.execute statement
    end

    def db_delete(statement)
      ActiveRecord::Base.connection.delete statement
    end
  end
end
