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

class CreateLlmCapabilityVerdicts < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_capability_verdicts do |t|
      t.references :llm_connection, null: false, foreign_key: true
      # A plain string, not a foreign key: the catalogue is a cache of a remote
      # list, and a model may vanish from it without invalidating what we learned.
      t.string :model_id, null: false
      t.string :capability, null: false
      t.string :state, null: false
      t.string :source, null: false
      t.jsonb :detail, null: false, default: {}
      t.datetime :checked_at, null: false

      t.timestamps null: false
    end

    add_index :llm_capability_verdicts,
              %i[llm_connection_id model_id capability],
              unique: true,
              name: "index_llm_capability_verdicts_on_connection_model_capability"
  end
end
