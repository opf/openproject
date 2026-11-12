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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

if ENV["OPENPROJECT_SKIP_DB_ENCODING_CHECK"].blank?
  icu_incompatible_encodings = %w[
    EUC_JIS_2004
    LATIN10
    MULE_INTERNAL
    SQL_ASCII
    WIN874
  ]

  database_encoding = ActiveRecord::Base.connection.select_value("SHOW SERVER_ENCODING")

  if database_encoding.in?(icu_incompatible_encodings)
    abort <<~ERROR
      INCOMPATIBLE DATABASE ENCODING DETECTED

      Your database encoding is #{database_encoding}, which is incompatible with ICU
      collation used in OpenProject v15.

      Please check the instructions on how to change database encoding:
      https://www.openproject.org/docs/installation-and-operations/misc/changing-database-encoding/

      This check can be skipped by setting environment variable OPENPROJECT_SKIP_DB_ENCODING_CHECK=true
    ERROR
  end
end
