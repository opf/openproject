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

class Tables::Journals < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.references :journable, polymorphic: true, index: false
      t.bigint :user_id, null: false, index: true
      t.text :notes, null: true
      t.datetime :created_at, precision: nil, null: false, index: true
      t.integer :version, default: 0, null: false
      t.datetime :updated_at, precision: nil, default: -> { "CURRENT_TIMESTAMP" }
      t.references :data, polymorphic: true, index: false, null: false
      t.jsonb :cause, default: {}
      t.tstzrange :validity_period
      t.boolean :restricted, default: false, null: false

      t.index :journable_id
      t.index :journable_type
      t.index %i[journable_type journable_id version],
              unique: true
      t.index %i[data_id data_type],
              unique: true
      t.index :notes,
              using: "gin",
              opclass: :gin_trgm_ops

      t.check_constraint "NOT isempty(validity_period) AND validity_period IS NOT NULL",
                         name: "journals_validity_period_not_empty"

      t.exclusion_constraint "journable_id WITH =, journable_type WITH =, validity_period WITH &&",
                             name: "non_overlapping_journals_validity_periods",
                             using: :gist,
                             deferrable: :immediate
    end
  end
end
