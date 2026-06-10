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

class Backlogs::Sprints::StartService < BaseServices::BaseContracted
  def initialize(user:, model:, contract_class: ::Backlogs::Sprints::StartContract)
    super(user:, contract_class:)
    self.model = model
  end

  private

  def persist(service_call)
    ensure_task_boards(service_call)
    return service_call if service_call.failure?

    model.active!

    service_call
  rescue ActiveRecord::RecordNotUnique
    add_only_one_active_sprint_error
    service_call.success = false
    service_call.result = model
    service_call.errors = model.errors
    service_call
  end

  def ensure_task_boards(service_call)
    projects = Sprint.receiving_projects(model)

    projects.each do |project|
      next if model.task_board_for(project).present?

      service_call.add_dependent!(
        Boards::SprintTaskBoardCreateService
          .new(user: User.system)
          .call(project:, sprint: model, name: board_name)
      )
    end
  end

  def board_name
    "#{model.project.name}: #{model.name}"
  end

  def add_only_one_active_sprint_error
    return if model.errors.added?(:status, :only_one_active_sprint_allowed)

    model.errors.add(:status, :only_one_active_sprint_allowed)
  end
end
