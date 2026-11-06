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

class ActivateLabelsInFormConfigurations < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO form_configuration_attributes
        (form_configuration_id, form_configuration_group_id, position, attribute_key, created_at, updated_at)
        SELECT fcg.form_configuration_id, fcg.id,
              COALESCE((SELECT MAX(fca.position) FROM form_configuration_attributes fca
                        WHERE fca.form_configuration_group_id = fcg.id), 0) + 1,
              'labels', NOW(), NOW()
        FROM form_configuration_groups fcg
        WHERE fcg.default_key = 'details'
      ON CONFLICT (form_configuration_id, attribute_key) WHERE attribute_key IS NOT NULL
      DO UPDATE SET form_configuration_group_id = EXCLUDED.form_configuration_group_id,
                    position = EXCLUDED.position,
                    updated_at = NOW()
      WHERE form_configuration_attributes.form_configuration_group_id IS NULL
    SQL

    execute "UPDATE form_configurations SET updated_at = NOW()"
  end

  def down; end
end
