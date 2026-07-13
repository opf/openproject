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

class UserWorkingHours::UpdateContract < UserWorkingHours::BaseContract
  attribute :user_id, writable: false

  def self.can_update?(user:, working_hours:)
    can_manage?(user:, target_user: working_hours.user) && working_hours.valid_from >= Date.current
  end

  validate :validate_valid_from_in_future

  private

  # Records that started in the past (valid_from before today) cannot be edited.
  # Use valid_from_was to check the original value before any changes in this request.
  # Falls back to the current valid_from for new/unsaved records (e.g., in tests).
  def validate_valid_from_in_future
    original_valid_from = model.valid_from_was.presence || model.valid_from
    return if original_valid_from.nil?

    unless original_valid_from >= Date.current
      errors.add :base, :not_editable
    end
  end
end
