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

class Workflows::BulkUpdateService < BaseServices::BaseCallable
  def initialize(role:, workflow:, tab:)
    super()
    @role = role
    @workflow = workflow
    @tab = tab
  end

  def call(status_transitions)
    valid = true

    Role.transaction do
      delete_current
      new_workflows = build_workflows(status_transitions)

      if (valid = new_workflows.each(&:valid?))
        bulk_insert(new_workflows)
      else
        raise ActiveRecord::Rollback
      end
    end

    ServiceResult.new success: valid, errors: role.errors
  end

  private

  attr_accessor :role, :workflow

  def build_workflows(status_transitions)
    new_workflows = []

    (status_transitions || {}).each do |status_id, transitions|
      transitions.each_key do |new_status_id|
        new_workflows << Workflows::StatusTransition.new(workflow:,
                                                         role:,
                                                         old_status: status_map[status_id.to_i],
                                                         new_status: status_map[new_status_id.to_i],
                                                         author: author?,
                                                         assignee: assignee?)
      end
    end

    new_workflows
  end

  def delete_current
    if author?
      current_workflows.where(author: true).delete_all
    elsif assignee?
      current_workflows.where(assignee: true).delete_all
    else
      current_workflows.where(assignee: false, author: false).delete_all
    end
  end

  def bulk_insert(workflows)
    return unless workflows.any?

    columns = %w(role_id workflow_id old_status_id new_status_id author assignee)
    values = workflows.map { |w| w.attributes.slice(*columns) }

    Workflows::StatusTransition.insert_all values
  end

  def current_workflows
    Workflows::StatusTransition.where(role_id: role.id, workflow_id: workflow.id)
  end

  def status_map
    @status_map ||= Status.all.group_by(&:id).transform_values(&:first)
  end

  def author?
    @tab == "author"
  end

  def assignee?
    @tab == "assignee"
  end
end
