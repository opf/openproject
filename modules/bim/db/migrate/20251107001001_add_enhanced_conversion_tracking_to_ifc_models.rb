# frozen_string_literal: true

# -- copyright
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
# ++

class AddEnhancedConversionTrackingToIfcModels < ActiveRecord::Migration[7.1]
  def change
    change_table :ifc_models, bulk: true do |t|
      # Current conversion stage (e.g., 'validation', 'ifc_to_dae', 'metadata_extraction')
      t.string :conversion_stage, limit: 50

      # Progress percentage (0-100)
      t.integer :conversion_progress, default: 0

      # Detailed logs per stage
      t.jsonb :conversion_logs, default: []
    end

    add_check_constraint :ifc_models,
                         "conversion_progress >= 0 AND conversion_progress <= 100",
                         name: "chk_ifc_models_progress_range"

    add_index :ifc_models, [:conversion_status, :conversion_stage]
  end
end
