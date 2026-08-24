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

class CreateLlmFeatureBindings < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_feature_bindings do |t|
      t.references :llm_connection, null: false, foreign_key: true
      t.string :feature_key, null: false
      # NULL means "use the connection default for this kind of model".
      t.string :model_id
      # Embedding features only. Frozen together with model_id once vectors exist.
      t.integer :dimensions
      t.string :input_prefix
      t.string :query_prefix
      # Set once the binding has data depending on it, after which the model
      # cannot be swapped without a destructive re-index.
      t.datetime :locked_at
      t.datetime :last_seen_at

      t.timestamps null: false
    end

    add_index :llm_feature_bindings, %i[llm_connection_id feature_key], unique: true
  end
end
