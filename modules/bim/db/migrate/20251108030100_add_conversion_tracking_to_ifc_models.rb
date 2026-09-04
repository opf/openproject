# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class AddConversionTrackingToIfcModels < ActiveRecord::Migration[8.0]
  def change
    # Add conversion tracking columns
    add_column :bim_ifc_models, :conversion_stage, :string, limit: 50
    add_column :bim_ifc_models, :conversion_progress, :integer, default: 0, null: false
    add_column :bim_ifc_models, :conversion_logs, :jsonb, default: [], null: false
    add_column :bim_ifc_models, :conversion_started_at, :datetime
    add_column :bim_ifc_models, :conversion_completed_at, :datetime

    # Add check constraint for progress (0-100)
    add_check_constraint :bim_ifc_models,
                         'conversion_progress >= 0 AND conversion_progress <= 100',
                         name: 'check_conversion_progress_range'

    # Add composite index for status tracking
    add_index :bim_ifc_models,
              [:conversion_status, :conversion_stage],
              name: 'index_ifc_models_on_conversion_tracking'

    # Add index for progress queries
    add_index :bim_ifc_models,
              :conversion_progress,
              name: 'index_ifc_models_on_progress'

    # GIN index for conversion logs JSONB
    add_index :bim_ifc_models,
              :conversion_logs,
              using: :gin,
              name: 'index_ifc_models_on_conversion_logs'
  end
end
