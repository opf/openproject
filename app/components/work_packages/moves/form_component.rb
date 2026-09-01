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

      def initialize(
        work_packages:,
        project:,
        target_project:,
        notes:,
        copy: false,
        selected_values: {},
        current_user: User.current
      )
        super

        @work_packages = work_packages
        @project = project
        @target_project = target_project
        @notes = notes
        @copy = copy
        @selected_values = selected_values.to_h.with_indifferent_access
        @current_user = current_user
      end

      private

      attr_reader :work_packages, :project, :target_project, :notes, :copy,
                  :selected_values, :current_user

      def turbo_stream_url
        url_helpers.refresh_form_move_work_packages_path
      end

      def available_variants
        @available_variants ||= target_project.enabled_variants.includes(:type).to_a
      end

      def available_type_ids
        @available_type_ids ||= available_variants.map(&:type_id)
      end

      def target_variant
        @target_variant ||= available_variants.find { |variant| variant.type_id.to_s == selected_values[:type_id].to_s }
      end

      def available_versions
        @available_versions ||= target_project.assignable_versions
      end

      def available_statuses
        @available_statuses ||= Workflow.available_statuses(target_project, current_user)
      end

      def unavailable_type_in_target_project?
        return false if target_project == project

        current_types_missing_in_target? || descendant_types_missing_in_target?
      end

      def current_types_missing_in_target?
        work_packages.map(&:type_id).uniq.difference(available_type_ids).any?
      end

      def descendant_types_missing_in_target?
        hierarchies = WorkPackageHierarchy
                        .includes(:descendant)
                        .where(ancestor_id: work_packages.map(&:id))
        Type.where(id: hierarchies.map { it.descendant.type_id })
            .select("distinct id")
            .pluck(:id)
            .difference(available_type_ids)
            .any?
      end

      def possible_assignees
        @possible_assignees ||= Principal.possible_assignee(target_project)
      end

      def selected_target_versions
        selected_ids = Array(selected_values[:target_version_ids]).map(&:to_s)

        available_versions.select { |version| selected_ids.include?(version.id.to_s) }
      end

      def selected_custom_field_value(custom_field)
        selected_values.dig(:custom_field_values, custom_field.id.to_s)
      end
    end
  end
end
