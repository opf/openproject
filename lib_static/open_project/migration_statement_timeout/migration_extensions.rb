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
  module MigrationExtensions
    attr_accessor :minimum_statement_timeout

    # Sets the minimum statement timeout for this migration.
    #
    # If the current statement timeout is lower than the given value, it will be
    # set to this value. It does nothing if the statement timeout is already set
    # to a higher value.
    #
    # When the given value is an integer or a string without units, it is
    # interpreted as milliseconds.
    #
    # When the given value is a string with units, it is interpreted
    # accordingly. Valid units for this parameter are "ms", "s", "min", and "h".
    # Examples: "15min", "90s", "2h".
    #
    # @param [Integer|String] timeout duration
    def set_minimum_statement_timeout(timeout)
      self.minimum_statement_timeout = timeout
    end
  end
end
