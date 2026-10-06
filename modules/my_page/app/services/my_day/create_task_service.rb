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
  # Creates a task in the user's "My work" project, due today in the given day part. Work packages
  # referenced as #123 or ##PROJ-42 get a "relates to" link the user is allowed to add.
  class CreateTaskService
    REFERENCE = /(?<![\w#])\#{1,3}(#{WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN.source}|\d+)\b/

    def initialize(user:)
      @user = user
    end

    def call(subject:, day_part:)
      ProjectService.new(user).call.bind do |project|
        create_task(project, subject, day_part)
          .on_success { |call| link_references(call.result) }
      end
    end

    private

    attr_reader :user

    def create_task(project, subject, day_part)
      day_part_field = DayPartField.find

      WorkPackages::CreateService
        .new(user:)
        .call(project:,
              type: SetupService.new.call.result.type,
              subject: subject.to_s.strip,
              start_date: user.today,
              due_date: user.today,
              "custom_field_#{day_part_field.id}": day_part_field.option_id_for(day_part))
    end

    def link_references(task)
      referenced_work_packages(task).each do |work_package|
        Relations::CreateService
          .new(user:)
          .call(from: task, to: work_package, relation_type: Relation::TYPE_RELATES)
      end
    end

    def referenced_work_packages(task)
      ids = task.subject.scan(REFERENCE).flatten.uniq
      return WorkPackage.none if ids.empty?

      WorkPackage.visible(user).where_display_id_in(ids).where.not(id: task.id)
    end
  end
end
