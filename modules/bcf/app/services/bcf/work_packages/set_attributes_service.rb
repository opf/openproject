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

module Bcf::WorkPackages
  class SetAttributesService < ::WorkPackages::SetAttributesService
    private

    def set_attributes(attributes)
      super(work_package_attributes(attributes))
    end

    def author(project, attributes)
      find_user_in_project(project, attributes[:author]) || User.system
    end

    def assignee(project, attributes)
      find_user_in_project(project, attributes[:assignee])
    end

    ##
    # Try to find the given user by mail in the project
    def find_user_in_project(project, mail)
      project.users.find_by(mail: mail)
    end

    def type(attributes)
      type_name = attributes[:type]
      type = ::Type.find_by(name: type_name)

      return type if type.present?

      import_options = attributes[:import_options]

      return ::Type.default&.first if !import_options || import_options[:unknown_types_action] == 'default'

      if import_options[:unknown_types_action] == 'chose' &&
         import_options[:unknown_types_chose_ids].any?
        ::Type.find_by(id: import_options[:unknown_types_chose_ids].first)
      else
        ServiceResult.new success: false,
                          errors: issue.errors,
                          result: issue
      end
    end

    def start_date(attributes)
      extractor.creation_date.to_date unless is_update
    end

    ##
    # Get mapped and raw attributes from MarkupExtractor
    # and return all values that are non-nil
    def work_package_attributes(attributes)
      project = Project.find(attributes[:project_id])

      {
        # Fixed attributes we know
        project: project,
        type: type(attributes),

        # Native attributes from the extractor
        subject: attributes[:title],
        description: attributes[:description],
        due_date: attributes[:due_date],
        start_date: attributes[:start_date],

        # Mapped attributes
        assigned_to: assignee(project, attributes),
        status_id: statuses.fetch(attributes[:status], statuses[:default]),
        priority_id: priorities.fetch(attributes[:priority], priorities[:default])
      }.compact
    end

    ##
    # Keep a hash map of current status ids for faster lookup
    def statuses
      @statuses ||= Hash[Status.pluck(:name, :id)].merge(default: Status.default.id)
    end

    ##
    # Keep a hash map of current status ids for faster lookup
    def priorities
      @priorities ||= Hash[IssuePriority.pluck(:name, :id)].merge(default: IssuePriority.default.try(:id))
    end
  end
end
