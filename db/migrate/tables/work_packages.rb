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

require_relative "base"

class Tables::WorkPackages < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.references :type, null: false, index: true, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :project, null: false, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.string :subject, default: "", null: false
      t.text :description
      t.date :due_date, index: true
      t.bigint :category_id, index: true
      t.references :status, null: false, index: true, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.bigint :assigned_to_id, index: true
      t.bigint :priority_id, null: true
      t.bigint :version_id, index: true
      t.bigint :author_id, null: false, index: true
      t.integer :lock_version, default: 0, null: false
      t.integer :done_ratio, default: nil, null: true
      t.float :estimated_hours
      t.timestamps precision: nil, null: true, index: true
      t.date :start_date, index: true
      t.belongs_to :responsible
      t.float :derived_estimated_hours
      t.boolean :schedule_manually, default: true, null: false
      t.bigint :parent_id, null: true, index: true
      t.integer :duration
      t.boolean :ignore_non_working_days, default: false, null: false
      t.float :derived_remaining_hours
      t.integer :derived_done_ratio, default: nil, null: true

      t.index %i[project_id updated_at]
      t.index :schedule_manually, where: :schedule_manually

      t.check_constraint "due_date >= start_date", name: "work_packages_due_larger_start_date"

      t.references :project_phase_definition, foreign_key: false, null: true
    end
  end
end
