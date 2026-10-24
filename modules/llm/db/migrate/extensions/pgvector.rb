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

require Rails.root.join("db/migrate/extensions/base").to_s

class Extensions::Pgvector < Extensions::Base
  extension "vector"
  creation_sql <<~SQL.squish
    CREATE EXTENSION IF NOT EXISTS vector;
  SQL
  module_text <<~MESSAGE

    \e[33mWARNING:\e[0m Could not find the `vector` extension for PostgreSQL.
    Please install pgvector for your PostgreSQL installation and re-run the migrations.

    Read more about installing pgvector at `https://github.com/pgvector/pgvector#installation`.

  MESSAGE
end
