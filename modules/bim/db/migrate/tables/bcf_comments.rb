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

require Rails.root.join("db/migrate/tables/base").to_s

class Tables::BcfComments < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.text :uuid
      t.references :journal, index: true
      t.references :issue,
                   foreign_key: { to_table: :bcf_issues, on_delete: :cascade },
                   index: true
      t.references :viewpoint, foreign_key: { to_table: :bcf_viewpoints, on_delete: :nullify }, index: true

      # Create unique index on issue and uuid to avoid duplicates on resynchronization
      t.index %i[uuid issue_id], unique: true
      t.index :uuid

      t.bigint :reply_to, default: nil, null: true
      t.foreign_key :bcf_comments, column: :reply_to, on_delete: :nullify
    end
  end
end
