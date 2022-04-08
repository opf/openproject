#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

class BigintPrimaryKeyOnRelations < ActiveRecord::Migration[6.1]
  def up
    change_relations_id(:bigint, 9223372036854775807)
  end

  def down
    change_relations_id(:integer, 2147483647)
  end

  private

  def change_relations_id(type, maxvalue)
    # We cannot simply use
    #
    # ALTER SEQUENCE relations_id_seq AS bigint;
    #
    # since that is not supported by PostgreSQL 9.6.
    execute <<~SQL.squish
      ALTER SEQUENCE relations_id_seq RENAME TO relations_id_seq_old;

      CREATE SEQUENCE IF NOT EXISTS relations_id_seq
        INCREMENT 1
        START 1
        MINVALUE 1
        MAXVALUE #{maxvalue}
        CACHE 1
        OWNED BY relations.id;

      SELECT setval('relations_id_seq', (SELECT MAX(id) + 1 FROM relations));
    SQL

    change_column :relations, :id, type, default: -> { "nextval('relations_id_seq')" }

    execute <<~SQL.squish
      DROP SEQUENCE relations_id_seq_old;
    SQL
  end
end
