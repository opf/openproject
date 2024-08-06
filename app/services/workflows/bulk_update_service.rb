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

class Workflows::BulkUpdateService < BaseServices::Update
  def initialize(role:, type:)
    @role = role
    @type = type
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

  attr_accessor :role, :type

  def build_workflows(status_transitions)
    new_workflows = []

    (status_transitions || {}).each do |status_id, transitions|
      transitions.each do |new_status_id, options|
        new_workflows << Workflow.new(type:,
                                      role:,
                                      old_status: status_map[status_id.to_i],
                                      new_status: status_map[new_status_id.to_i],
                                      author: options_include(options, "author"),
                                      assignee: options_include(options, "assignee"))
      end
    end

    new_workflows
  end

  def delete_current
    Workflow.where(role_id: role.id, type_id: type.id).delete_all
  end

  def bulk_insert(workflows)
    return unless workflows.any?

    columns = %w(role_id type_id old_status_id new_status_id author assignee)
    values = workflows.map { |w| w.attributes.slice(*columns) }

    Workflow.insert_all values
  end

  def status_map
    @status_map ||= Status.all.group_by(&:id).transform_values(&:first)
  end

  def options_include(options, string)
    options.is_a?(Array) && options.include?(string) && !options.include?("always")
  end
end
