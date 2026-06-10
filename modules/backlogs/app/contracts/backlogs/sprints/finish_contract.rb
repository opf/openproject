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

module Backlogs::Sprints
  class FinishContract < ModelContract
    validate :sprint_must_be_active
    validate :user_allowed_to_finish
    validate :no_unfinished_work_packages

    def self.model
      Sprint
    end

    private

    def sprint_must_be_active
      errors.add(:status, :not_active) unless model.active?
    end

    def user_allowed_to_finish
      errors.add(:base, :error_unauthorized) unless user.allowed_in_project?(:start_complete_sprint, model.project)
    end

    def no_unfinished_work_packages
      unfinished_work_package_count = model.work_packages.without_status_considered_closed.count

      errors.add(:base, :unfinished_work_packages, count: unfinished_work_package_count) if unfinished_work_package_count > 0
    end
  end
end
