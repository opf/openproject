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

module Bim::Bcf
  module Issues
    class TransformAttributesService
      def initialize(project)
        self.project = project
      end

      def call(attributes, fill_defaults: true)
        ServiceResult.success result: work_package_attributes(attributes, fill_defaults:)
      end

      private

      attr_accessor :project

      ##
      # BCF issues might have empty titles. OP needs one.
      def title(attributes)
        if attributes[:title]
          attributes[:title]
        elsif attributes[:import_options]
          "(Imported BCF issue contained no title)"
        end
      end

      def author(project, attributes)
        find_user_in_project(project, attributes[:author]) || User.system
      end

      def assignee(attributes)
        assignee = find_user(attributes[:assignee])

        return assignee if assignee.present?

        missing_assignee(attributes[:assignee], attributes[:import_options] || {})
      end

      ##
      # Try to find the given user by mail in the project
      def find_user(mail)
        project.users.find_by(mail:)
      end

      def type(attributes)
        type_name = attributes[:type]
        type = project.enabled_types.find_by(name: type_name)

        return type if type.present?

        missing_type(type_name, attributes[:import_options] || {})
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
      # and return all values that are non-nil.
      #
      # +fill_defaults+ applies create-time type/status/priority when omitted. The BCF API
      # passes false and supplies create vs put defaults itself via reverse_merge, so a PUT
      # that omits topic_type is not forced onto default_create_type.
      def work_package_attributes(attributes, fill_defaults: true) # rubocop:disable Metrics/AbcSize
        import_options = attributes[:import_options] || {}
        resolved_type = type(attributes)
        resolved_status = status(attributes)
        resolved_priority = priority(attributes)

        if fill_defaults && import_options.empty?
          resolved_type ||= DefaultWorkPackageAttributes.default_create_type(project)
          resolved_status ||= DefaultWorkPackageAttributes.default_status(project, type: resolved_type)
          resolved_priority ||= DefaultWorkPackageAttributes.default_priority
        end

        {
          type: resolved_type,

          # Native attributes from the extractor
          subject: title(attributes),
          description: attributes[:description],
          due_date: attributes[:due_date],
          start_date: attributes[:start_date],

          # Mapped attributes
          assigned_to: assignee(attributes),
          status: resolved_status,
          priority: resolved_priority
        }.compact
      end

      def missing_status(status_name, import_options)
        if import_options[:unknown_statuses_action] == "use_default"
          default_type = DefaultWorkPackageAttributes.default_create_type(project)
          DefaultWorkPackageAttributes.default_status(project, type: default_type)
        elsif import_options[:unknown_statuses_action] == "chose" &&
              import_options[:unknown_statuses_chose_ids].any?
          ::Status.find_by(id: import_options[:unknown_statuses_chose_ids].first)
        elsif status_name
          Status::InexistentStatus.new
        end
      end

      def missing_priority(priority_name, import_options)
        if import_options[:unknown_priorities_action] == "use_default"
          # NOP The 'use_default' case gets already covered by OP.
        elsif import_options[:unknown_priorities_action] == "chose" &&
              import_options[:unknown_priorities_chose_ids].any?
          ::IssuePriority.find_by(id: import_options[:unknown_priorities_chose_ids].first)
        elsif priority_name
          Priority::InexistentPriority.new
        end
      end

      # A project_type names the configuration the project applies; the work package is typed
      # by the type itself, so the row is only the way in.
      def missing_type(type_name, import_options)
        if import_options[:unknown_types_action] == "use_default"
          project_type_for_new_projects&.type
        elsif chosen_type_id(import_options)
          chosen_project_type(import_options)&.type
        elsif type_name
          Type::InexistentType.new
        end
      end

      def enabled_project_types
        project.project_types.includes(:type, :variant)
      end

      def project_type_for_new_projects
        enabled_project_types.find { |project_type| project_type.variant.enabled_in_new_projects? }
      end

      def chosen_type_id(import_options)
        return unless import_options[:unknown_types_action] == "chose"

        import_options[:unknown_types_chose_ids]&.first
      end

      def chosen_project_type(import_options)
        chosen_id = chosen_type_id(import_options)

        enabled_project_types.find { |project_type| project_type.type_id == chosen_id }
      end

      def missing_assignee(assignee_name, import_options)
        if import_options[:invalid_people_action] != "anonymize" && assignee_name
          Users::InexistentUser.new
        end
      end
    end
  end
end
