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

module WorkPackages
  module Moves
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpenProject::FormTagHelper
      include AngularHelper
      include VersionsHelper
      include CustomFieldsHelper
      include HookHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(work_packages:, project:, target_project:, types:, available_versions:, available_statuses:,
                     notes:, turbo_stream_url:, copy: false, target_type: nil,
                     unavailable_type_in_target_project: false, selected_values: {})
        super

        @work_packages = work_packages
        @project = project
        @target_project = target_project
        @types = types
        @target_type = target_type
        @unavailable_type_in_target_project = unavailable_type_in_target_project
        @available_versions = available_versions
        @available_statuses = available_statuses
        @notes = notes
        @copy = copy
        @selected_values = selected_values
        @turbo_stream_url = turbo_stream_url
      end

      private

      attr_reader :work_packages, :project, :target_project, :types, :target_type,
                  :unavailable_type_in_target_project, :available_versions, :available_statuses, :notes, :copy,
                  :selected_values, :turbo_stream_url

      def possible_assignees
        @possible_assignees ||= Principal.possible_assignee(target_project)
      end

      def selected_value(attribute)
        selected_values[attribute] || selected_values[attribute.to_s]
      end

      def selected_version
        available_versions.find { |version| version.id.to_s == selected_value(:version_id).to_s }
      end

      def selected_custom_field_value(custom_field)
        selected_value(:custom_field_values)&.[](custom_field.id.to_s)
      end
    end
  end
end
