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

module ResourceAllocations
  class BaseContract < ::ModelContract
    def self.model
      ResourceAllocation
    end

    attribute :principal
    attribute :placeholder_user
    attribute :state
    attribute :start_date
    attribute :end_date
    attribute :allocated_time

    validate :user_allowed_to_allocate
    validate :principal_must_be_member

    private

    # The permission lives on the project of the allocated work package, which is
    # also how a global planner resolves it. A missing project means no reachable
    # entity, so there is nothing to authorise against.
    def user_allowed_to_allocate
      return if model.project && user.allowed_in_project?(:allocate_user_resources, model.project)

      errors.add :base, :error_unauthorized
    end

    def principal_must_be_member
      return if model.principal.nil? || model.project.nil?
      return if Principal.in_project(model.project).exists?(id: model.principal_id)

      errors.add :principal, :not_a_member
    end
  end
end
