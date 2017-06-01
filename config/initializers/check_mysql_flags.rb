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

if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter) &&
   ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)

  db_flags = ActiveRecord::Base.connection.execute('SELECT @@SESSION.sql_mode').first.first

  expected_flags = %w{no_auto_value_on_zero
                      strict_all_tables
                      strict_trans_tables
                      no_zero_in_date
                      no_zero_date
                      error_for_division_by_zero
                      no_auto_create_user
                      no_engine_substitution}

  unless expected_flags & db_flags.downcase.split(',') == expected_flags

    message = <<-MESSAGE

      *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *

      *   OpenProject expects to have the following sql modes set on MySql.      *

      *   Please ensure having set:                                              *

      *     variables:                                                           *
              sql_mode:
      *         "no_auto_value_on_zero,\                                         *
                strict_trans_tables,\
      *         strict_all_tables,\                                              *
                no_zero_in_date,\
      *         no_zero_date,\                                                   *
                error_for_division_by_zero,\
      *         no_auto_create_user,\                                            *
                no_engine_substitution"
      *                                                                          *
         for the #{Rails.env} environment in config/database.yml
      *                                                                          *
      *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *

    MESSAGE

    raise message
  end
end
