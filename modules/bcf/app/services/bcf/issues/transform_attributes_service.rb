#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Bcf::Issues
  class TransformAttributesService
    def call(attributes)
      ServiceResult.new success: true,
                        result: work_package_attributes(attributes)
    end

    private

    ##
    # BCF issues might have empty titles. OP needs one.
    def title(attributes)
      if attributes[:title]
        attributes[:title]
      elsif attributes[:import_options]
        '(Imported BCF issue contained no title)'
      end
    end

    def author(project, attributes)
      find_user_in_project(project, attributes[:author]) || User.system
    end

    def assignee(project, attributes)
      assignee = find_user_in_project(project, attributes[:assignee])

      return assignee if assignee.present?

      missing_assignee(attributes[:assignee], attributes[:import_options] || {})
    end

    ##
    # Try to find the given user by mail in the project
    def find_user_in_project(project, mail)
      project.users.find_by(mail: mail)
    end

    def type(project, attributes)
      type_name = attributes[:type]
      type = project.types.find_by(name: type_name)

      return type if type.present?

      missing_type(project, type_name, attributes[:import_options] || {})
    end

    ##
    # Handle unknown statuses during import
    def status(attributes)
      status_name = attributes[:status]
      status = ::Status.find_by(name: status_name)

      return status if status.present?

      missing_status(status_name, attributes[:import_options] || {})
    end

    ##
    # Handle unknown priorities during import
    def priority(attributes)
      priority_name = attributes[:priority]
      priority = ::IssuePriority.find_by(name: priority_name)

      return priority if priority.present?

      missing_priority(priority_name, attributes[:import_options] || {})
    end

    ##
    # Get mapped and raw attributes from MarkupExtractor
    # and return all values that are non-nil
    def work_package_attributes(attributes)
      project = Project.find(attributes[:project_id])

      {
        # Fixed attributes we know
        project: project,
        type: type(project, attributes),

        # Native attributes from the extractor
        subject: title(attributes),
        description: attributes[:description],
        due_date: attributes[:due_date],
        start_date: attributes[:start_date],

        # Mapped attributes
        assigned_to: assignee(project, attributes),
        status: status(attributes),
        priority: priority(attributes)
      }.compact
    end

    def missing_status(status_name, import_options)
      if import_options[:unknown_statuses_action] == 'use_default'
        ::Status.default
      elsif import_options[:unknown_statuses_action] == 'chose' &&
            import_options[:unknown_statuses_chose_ids].any?
        ::Status.find_by(id: import_options[:unknown_statuses_chose_ids].first)
      elsif status_name
        Status::InexistentStatus.new
      end
    end

    def missing_priority(priority_name, import_options)
      if import_options[:unknown_priorities_action] == 'use_default'
        # NOP The 'use_default' case gets already covered by OP.
      elsif import_options[:unknown_priorities_action] == 'chose' &&
            import_options[:unknown_priorities_chose_ids].any?
        ::IssuePriority.find_by(id: import_options[:unknown_priorities_chose_ids].first)
      elsif priority_name
        Priority::InexistentPriority.new
      end
    end

    def missing_type(project, type_name, import_options)
      if import_options[:unknown_types_action] == 'use_default'
        project.types.default&.first
      elsif import_options[:unknown_types_action] == 'chose' &&
            import_options[:unknown_types_chose_ids].any?
        project.types.find_by(id: import_options[:unknown_types_chose_ids].first)
      elsif type_name
        Type::InexistentType.new
      end
    end

    def missing_assignee(assignee_name, import_options)
      if import_options[:invalid_people_action] != 'anonymize' && assignee_name
        User::InexistentUser.new
      end
    end
  end
end
