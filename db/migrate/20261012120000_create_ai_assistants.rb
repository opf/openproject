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

class CreateAIAssistants < ActiveRecord::Migration[8.1]
  def change
    create_assistants
    create_skills
    create_runs
    create_findings
  end

  private

  def create_assistants
    create_table :ai_assistants do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.string :icon
      # Not a foreign key: syncing the models of an LLM connection replaces the llm_models rows.
      t.string :model_id
      t.integer :position
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end

  def create_skills
    create_table :ai_assistant_skills do |t|
      t.references :assistant, null: false, foreign_key: { to_table: :ai_assistants, on_delete: :cascade }, index: false
      t.string :skill_key, null: false
      # Shown in the menu; empty uses the text of the skill type.
      t.string :label
      t.text :description
      # The prompt is data, not code: the instructions and the output rules. Templates for
      # them come from a registry outside OpenProject; template_ref names the one a
      # skill was created from.
      t.text :prompt
      t.text :output_rules
      t.string :template_ref
      # A read-only skill reports findings only. Otherwise it may propose changes to the
      # attributes its type supports; the workflow and permissions decide the values.
      t.boolean :read_only, null: false, default: false
      t.integer :position
      t.boolean :active, null: false, default: true

      t.timestamps

      # Not unique: one assistant can have several variants of a skill type, each with
      # its own label, prompt and attributes.
      t.index %i[assistant_id skill_key]
    end
  end

  def create_runs
    create_table :ai_assistant_runs do |t|
      t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }, index: { unique: true }
      t.references :skill, null: false, foreign_key: { to_table: :ai_assistant_skills, on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :work_package, null: false, foreign_key: { on_delete: :cascade }
      t.integer :lock_version, null: false
      # Why the run started: "menu" now; "automation" and "schedule" once Automations can run skills.
      t.string :trigger, null: false, default: "menu"
      t.references :automation, foreign_key: { on_delete: :nullify }, index: false
      t.string :status, null: false, default: "running"
      t.string :locale, null: false
      t.jsonb :not_checked, null: false, default: []
      # What happened during the run, shown in the run dialog: [{at, kind, data}].
      t.jsonb :events, null: false, default: []
      t.string :error_message
      t.datetime :finished_at

      t.timestamps

      t.index %i[user_id work_package_id created_at]
    end
  end

  def create_findings
    create_table :ai_assistant_run_findings do |t|
      t.references :run, null: false, foreign_key: { to_table: :ai_assistant_runs, on_delete: :cascade }, index: false
      t.string :source, null: false
      t.string :rule_key
      t.string :severity, null: false
      t.string :area, null: false
      t.text :text, null: false
      t.jsonb :evidence, null: false, default: []
      t.jsonb :change_set
      t.integer :base_lock_version
      t.string :state, null: false, default: "open"
      t.string :dismiss_reason

      t.timestamps

      t.index %i[run_id id]
    end
  end
end
