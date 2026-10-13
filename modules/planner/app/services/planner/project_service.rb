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

module Planner
  # The user's private "My work" project, created on first use. Its id is kept in the user's
  # preferences; a project the user has left or that was archived is replaced by a new one.
  class ProjectService
    MODULES = %w[work_package_tracking].freeze

    def initialize(user)
      @user = user
    end

    def call
      return ServiceResult.success(result: existing_project) if existing_project

      OpenProject::Mutex.with_advisory_lock(User, "planner_project_#{user.id}") do
        # Another request may have created the project while this one waited for the lock.
        user.pref.reload if user.pref.persisted?
        existing_project ? ServiceResult.success(result: existing_project) : create_project
      end
    end

    private

    attr_reader :user

    def existing_project
      @existing_project ||= Project
                              .active
                              .where(id: user.pref.planner_project_id)
                              .find { user.member_of?(it) }
    end

    def create_project
      SetupService.new.call
        .bind { |variant| create_private_project(variant) }
        .bind { |project| add_member(project) }
        .on_success { |call| user.pref.update!(planner_project_id: call.result.id) }
    end

    def create_private_project(variant)
      Projects::CreateService
        .new(user: User.system)
        .call(name: I18n.t("planner.project_name"), public: false, workspace_type: "project")
        .on_success do |call|
          call.result.update!(enabled_module_names: MODULES,
                              project_types: [ProjectType.new(type: variant.type, variant:)])
        end
    end

    def add_member(project)
      Members::CreateService
        .new(user: User.system, contract_class: EmptyContract)
        .call(project:, principal: user, roles: [ProjectRole.in_new_project], send_notifications: false)
        .map { project }
    end
  end
end
