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

class UserWorkingHours::BaseContract < ModelContract
  attribute :user_id
  attribute :valid_from
  ::UserWorkingHours::DAYS.each { |day| attribute :"#{day}_hours" }
  attribute :availability_factor

  validate :validate_manage_permission
  # TODO: Possibly add a validation that we only add working hours for future dates. We will start without it for
  #       now, but let's consider adding it in the future to prevent users from accidentally changing their historic
  #       data.

  def self.model = ::UserWorkingHours

  def self.can_manage?(user:, target_user:)
    user.allowed_globally?(:manage_working_times) ||
      (target_user.id == user.id && user.allowed_globally?(:manage_own_working_times))
  end

  private

  def validate_manage_permission
    unless can_manage_working_hours?
      errors.add :base, :error_unauthorized
    end
  end

  def can_manage_working_hours?
    user.allowed_globally?(:manage_working_times) ||
      (model.user_id == user.id && user.allowed_globally?(:manage_own_working_times))
  end

  # The model stores day values as minutes (e.g. `monday`), but the public
  # interface uses hours (e.g. `monday_hours`). When `monday_hours=` is called,
  # the underlying `monday` column becomes dirty. Override `changed_by_user` to
  # map those raw column names back to their hours equivalents so the writable
  # attribute check passes correctly.
  def changed_by_user
    day_names = ::UserWorkingHours::DAYS.map(&:to_s)
    super.map { |attr| day_names.include?(attr) ? "#{attr}_hours" : attr }
  end
end
