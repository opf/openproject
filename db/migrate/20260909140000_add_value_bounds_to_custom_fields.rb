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

class AddValueBoundsToCustomFields < ActiveRecord::Migration[8.1]
  # Convert at max 15 digits to try and get the correct range values
  # A double precision column holds integers exactly up to 2^53, which is approximately 9e15.
  # A longer length gives a bound that is not exact so we skip those
  MAX_CONVERTIBLE_LENGTH = 15

  def up
    change_table :custom_fields, bulk: true do |t|
      t.float :min_value, null: true
      t.float :max_value, null: true
    end

    execute <<~SQL.squish
      UPDATE custom_fields
      SET min_value = CASE
                        WHEN min_length BETWEEN 2 AND #{MAX_CONVERTIBLE_LENGTH}
                        THEN power(10::double precision, min_length - 1)
                      END,
          max_value = CASE
                        WHEN max_length BETWEEN 1 AND #{MAX_CONVERTIBLE_LENGTH}
                        THEN power(10::double precision, max_length) - 1
                      END,
          min_length = 0,
          max_length = 0
      WHERE field_format IN ('int', 'float')
    SQL
  end

  def down
    change_table :custom_fields, bulk: true do |t|
      t.remove :min_value, :max_value
    end
  end
end
