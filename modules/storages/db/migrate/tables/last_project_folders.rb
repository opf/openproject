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

class Tables::LastProjectFolders < Tables::Base
  def self.table(migration)
    create_table migration,
                 comment: "This table contains the last used project folder IDs for a project storage per mode." do |t|
      t.references :project_storage, null: false, foreign_key: { on_delete: :cascade, name: "fk_rails_73e1c678f1" }
      t.string :origin_folder_id
      t.string :mode, enum_type: :project_folder_modes, default: "inactive", null: false
      t.index %i[project_storage_id mode], unique: true
      t.timestamps

      t.check_constraint("mode IN ('inactive', 'manual', 'automatic')",
                         name: "last_project_folders_mode_check")
    end
  end
end
