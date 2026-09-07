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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreateAITextTransformRuns < ActiveRecord::Migration[8.1]
  def change
    create_runs
    create_run_events
  end

  private

  def create_runs
    create_table :ai_text_transform_runs do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :ai_text_transform_action, null: false, foreign_key: { on_delete: :cascade }
      t.string :status, null: false, default: "queued"
      t.text :system_prompt, null: false
      t.text :input, null: false
      t.boolean :cancel_requested, null: false, default: false
      t.string :error_message
      t.datetime :finished_at, index: true

      t.timestamps
    end
  end

  def create_run_events
    create_table :ai_text_transform_run_events do |t|
      t.references :run, null: false, foreign_key: { to_table: :ai_text_transform_runs, on_delete: :cascade }, index: false
      t.integer :seq, null: false
      t.string :kind, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :created_at, null: false

      t.index %i[run_id seq], unique: true
    end
  end
end
