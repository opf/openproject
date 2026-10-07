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

module MyDay
  # The user's personal backlog: open "My work" tasks that are not planned for today or later,
  # either left over from an earlier day or never planned.
  class Unplanned
    attr_reader :user, :project

    def self.for(user)
      call = ProjectService.new(user).call
      new(user:, project: call.result) if call.success?
    end

    def initialize(user:, project:)
      @user = user
      @project = project
    end

    def work_packages
      @work_packages ||= project
                           .work_packages
                           .with_status_open
                           .where(left_over_or_undated)
                           .includes(:type, :project, :custom_values)
                           .order(due_date.asc.nulls_last, id: :desc)
                           .to_a
    end

    def count = work_packages.size

    def references
      @references ||= References.for(user, work_packages)
    end

    private

    def due_date = WorkPackage.arel_table[:due_date]

    def left_over_or_undated = due_date.eq(nil).or(due_date.lt(user.today))
  end
end
