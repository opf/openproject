# frozen_string_literal: true

# -- copyright
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
# ++

require_relative "base"

class Extensions::VersionsNameCollation < Extensions::Base
  creation_sql <<~SQL.squish
    CREATE COLLATION IF NOT EXISTS versions_name (provider = icu, locale = "und-u-kn-true")
  SQL
  extension "encoding"
  module_text <<~MESSAGE

    \e[31mERROR:\e[0m Failed to create an ICU collation with current database encoding.
    You need to change the database encoding before proceeding.

    Please check the instructions on how to do it:
    https://www.openproject.org/docs/installation-and-operations/misc/changing-database-encoding/

  MESSAGE
end
