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

class Queries::CostTypes::Filters::StatusFilter < Queries::Filters::Base
  ACTIVE_VALUE = "active"
  LOCKED_VALUE = "locked"

  self.model = CostType

  validate :validate_single_value

  def allowed_values
    [
      [I18n.t(:label_active), ACTIVE_VALUE],
      [I18n.t("members.menu.locked"), LOCKED_VALUE]
    ]
  end

  def where
    if values.first == LOCKED_VALUE
      "cost_types.deleted_at IS NOT NULL"
    else
      "cost_types.deleted_at IS NULL"
    end
  end

  def human_name
    I18n.t(:label_status)
  end

  def type
    :list
  end

  def self.key
    :status
  end

  def available_operators
    [::Queries::Operators::Equals]
  end

  private

  def validate_single_value
    errors.add(:values, :invalid) if values.length != 1
  end
end
