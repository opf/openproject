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

class Tables::ProjectStorages < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade, name: "fk_rails_96ab713fe3" }
      t.references :storage, null: false, foreign_key: { on_delete: :cascade, name: "fk_rails_04546d7b88" }
      t.references :creator,
                   null: false,
                   index: true,
                   foreign_key: { to_table: :users, name: "fk_rails_acca00a591" }

      t.timestamps precision: nil
      t.string :project_folder_id
      t.string :project_folder_mode, null: false, default: nil

      t.index %i[project_id storage_id], unique: true

      t.check_constraint("project_folder_mode IN ('inactive', 'manual', 'automatic')",
                         name: "project_storages_project_folder_mode_check")
    end
  end
end
