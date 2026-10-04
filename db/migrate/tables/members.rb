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

require_relative "base"

class Tables::Members < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.references :user, null: false, index: { name: "index_members_on_user_id" }
      t.references :project, default: nil, null: true, index: { name: "index_members_on_project_id" }
      t.datetime :created_at, precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: true
      t.datetime :updated_at, precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.references :entity, foreign_key: false, polymorphic: true, index: true

      t.index %i[user_id project_id],
              unique: true,
              where: "entity_type IS NULL AND entity_id IS NULL",
              name: "index_members_on_user_id_and_project_without_entity"

      t.index %i[user_id project_id entity_type entity_id],
              unique: true,
              where: "entity_type IS NOT NULL AND entity_id IS NOT NULL",
              name: "index_members_on_user_id_and_project_with_entity"
    end
  end
end
