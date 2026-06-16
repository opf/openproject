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

class Backlogs::Sprints::FinishService < BaseServices::BaseContracted
  def initialize(user:, model:)
    super(user:)
    self.model = model
  end

  protected

  def before_perform(service_call)
    case params[:unfinished_action]
    when "move_to_sprint"
      @target_sprint = Sprint.find_by(id: params[:move_to_sprint_id])
      move_to_sprint(@target_sprint).each { |result| service_call.add_dependent!(result) }
    when "move_to_top_of_backlog"
      move_to_backlog(position: 1).each { |result| service_call.add_dependent!(result) }
    when "move_to_bottom_of_backlog"
      move_to_backlog(position: nil).each { |result| service_call.add_dependent!(result) }
    end

    service_call
  end

  def persist(service_call)
    model.completed!
    service_call
  end

  def default_contract_class
    ::Backlogs::Sprints::FinishContract
  end

  private

  def open_work_packages
    model.work_packages.without_status_considered_closed
  end

  def move_to_sprint(target_sprint)
    open_work_packages.order(position: :desc).map do |wp|
      ::WorkPackages::UpdateService
        .new(user:, model: wp, contract_class: ::Backlogs::WorkPackages::MoveBetweenSprintsContract)
        .call(sprint: target_sprint, position: 1)
    end
  end

  def move_to_backlog(position:)
    # Process descending for top (each inserted at 1 preserves original order at top),
    # ascending for bottom (each appended to end preserves original order at bottom).
    order_direction = position ? :desc : :asc
    call_args = { sprint: nil }
    call_args[:position] = position if position

    open_work_packages.order(position: order_direction).map do |wp|
      ::WorkPackages::UpdateService
        .new(user:, model: wp, contract_class: ::Backlogs::WorkPackages::MoveToBacklogContract)
        .call(**call_args)
    end
  end
end
