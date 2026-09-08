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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Projects are searched by name or identifier with a leading-wildcard
# LIKE on the LOWER() of both columns (see
# Queries::Projects::Filters::NameAndIdentifierFilter and
# Header::ProjectsController). A btree index cannot serve such a predicate,
# so add trigram indexes on the very expressions used by those queries.
class AddTrigramIndexesForProjectNameAndIdentifierSearch < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # Distinct names are required because index_projects_on_lower_identifier
  # (a unique btree for case-insensitive uniqueness) already indexes the
  # LOWER(identifier) expression.
  #
  # The operator class is spelled out inside the expression because the
  # +opclass:+ option only applies to plain column indexes.
  def up
    add_index :projects, "LOWER(name) gin_trgm_ops",
              using: :gin,
              name: "index_projects_on_lower_name_trgm",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :projects, "LOWER(identifier) gin_trgm_ops",
              using: :gin,
              name: "index_projects_on_lower_identifier_trgm",
              algorithm: :concurrently,
              if_not_exists: true
  end

  def down
    remove_index :projects, name: "index_projects_on_lower_name_trgm", algorithm: :concurrently, if_exists: true
    remove_index :projects, name: "index_projects_on_lower_identifier_trgm", algorithm: :concurrently, if_exists: true
  end
end
