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

class AddWikiPagesFullTextIndex < ActiveRecord::Migration[8.1]
  INDEX_NAME = "index_wiki_pages_on_full_text_search"

  def up
    return if wiki_pages_full_text_index_exists?

    ts_config = ::OpenProject::WikiAPI::Search.ts_config

    execute <<~SQL.squish
      CREATE INDEX #{INDEX_NAME} ON wiki_pages
      USING GIN (
        to_tsvector(#{connection.quote(ts_config)},
                    coalesce(title, '') || ' ' || coalesce(text, ''))
      )
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS #{INDEX_NAME}"
  end

  private

  def wiki_pages_full_text_index_exists?
    connection.select_value(<<~SQL.squish).present?
      SELECT 1 FROM pg_indexes WHERE indexname = '#{INDEX_NAME}'
    SQL
  end
end
