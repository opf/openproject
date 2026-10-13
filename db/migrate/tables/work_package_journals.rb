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

class Tables::WorkPackageJournals < Tables::Base
  # rubocop:disable Metrics/AbcSize
  def self.table(migration)
    create_table migration do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.bigint :type_id, null: false, index: true
      t.bigint :project_id, null: false, index: true
      t.string :subject, default: nil, null: false
      t.text :description
      t.date :due_date, index: true
      t.bigint :category_id, index: true
      t.bigint :status_id, null: false, index: true
      t.bigint :assigned_to_id, index: true
      t.bigint :priority_id, null: false
      t.bigint :version_id, index: true
      t.bigint :author_id, null: false, index: true
      t.integer :done_ratio, default: nil, null: true
      t.float :estimated_hours
      t.date :start_date, index: true
      t.bigint :parent_id, index: true
      t.bigint :responsible_id, index: true
      t.float :derived_estimated_hours
      t.boolean :schedule_manually, default: nil, index: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.integer :duration
      t.boolean :ignore_non_working_days, null: false # rubocop:disable Rails/ThreeStateBooleanColumn
      t.float :derived_remaining_hours
      t.integer :derived_done_ratio, default: nil, null: true
      t.bigint :project_phase_definition_id, null: true
    end
    # rubocop:enable Metrics/AbcSize
  end
end
