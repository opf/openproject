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

class ModifyFriendlyIdSlugsConstraints < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicate NULL scope rows, keeping the most recent one per (slug, sluggable_type)
    say_with_time "Cleaning up duplicate NULL scope rows" do
      execute <<~SQL.squish
        DELETE FROM friendly_id_slugs
        WHERE scope IS NULL
          AND id NOT IN (
            SELECT DISTINCT ON (slug, sluggable_type) id
            FROM friendly_id_slugs
            WHERE scope IS NULL
            ORDER BY slug, sluggable_type, created_at DESC NULLS LAST, id DESC
          );
      SQL
    end

    say_with_time "Cleaning up NULL sluggable_type rows" do
      execute <<~SQL.squish
        DELETE FROM friendly_id_slugs
        WHERE sluggable_type IS NULL;
      SQL
    end

    change_column_null :friendly_id_slugs, :sluggable_type, false

    remove_index :friendly_id_slugs,
                 name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope"

    # create index that treats every null value as unique
    execute <<~SQL.squish
      CREATE UNIQUE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope
      ON friendly_id_slugs (slug, sluggable_type, scope)
      NULLS NOT DISTINCT;
    SQL
  end

  def down
    remove_index :friendly_id_slugs,
                 name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope"

    change_column_null :friendly_id_slugs, :sluggable_type, true

    add_index :friendly_id_slugs,
              %i[slug sluggable_type scope],
              unique: true,
              name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope"
  end
end
