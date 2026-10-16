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

module RecurringWorkPackages
  class CreateNextOnCloseService
    attr_reader :current_user, :work_package

    def initialize(current_user:, work_package:)
      @current_user = current_user
      @work_package = work_package
    end

    def self.applicable?(work_package:, changes:)
      closing?(*Array(changes["status_id"])) && Occurrence.find_by(work_package:)&.latest?
    end

    def self.closing?(old_status_id = nil, new_status_id = nil)
      return false if old_status_id.blank? || new_status_id.blank?

      statuses = Status.where(id: [old_status_id, new_status_id]).index_by(&:id)
      !statuses[old_status_id]&.is_closed? && statuses[new_status_id]&.is_closed?
    end

    def call!(changes:)
      return unless self.class.applicable?(work_package:, changes:)

      series = Occurrence.find_by(work_package:).series
      CreateNextService.new(user: current_user, series:).call
    end
  end
end
