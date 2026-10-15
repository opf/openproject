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
  class CreateTaskService
    def initialize(user:, project:)
      @user = user
      @project = project
    end

    def call(subject:, day_part: nil, date: user.today, description: nil)
      create_task(subject:, day_part:, date:, description:)
        .on_success { |call| link_references(call.result) }
    end

    private

    attr_reader :user, :project

    def create_task(subject:, day_part:, date:, description:)
      WorkPackages::CreateService
        .new(user:)
        .call(project:,
              type: project.project_types.first.type,
              subject: subject.to_s.strip,
              description: description.presence,
              start_date: date,
              due_date: date,
              **DayPartField.find.attributes_for(day_part))
    end

    def link_references(task)
      (References.for(user, [task]).values.uniq - [task]).each do |work_package|
        Relations::CreateService
          .new(user:)
          .call(from: task, to: work_package, relation_type: Relation::TYPE_RELATES)
      end
    end
  end
end
