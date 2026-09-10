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

module Admin
  module TextTransformActions
    class SandboxForm < ApplicationForm
      MODE_TARGET_NAME = "sandbox_context_mode"
      MODES = %w[none work_package new_work_package].freeze

      form do |f|
        f.text_area(
          name: :content,
          label: label(:content_label),
          caption: label(:content_caption),
          rows: 10,
          full_width: true,
          data: target(:content)
        )

        f.select_list(
          name: :context_mode,
          label: label(:context_label),
          caption: label(:context_caption),
          include_blank: false,
          data: target(:contextMode).merge(show_when_value_selected_target: "cause", target_name: MODE_TARGET_NAME)
        ) do |select|
          MODES.each { |mode| select.option(value: mode, label: label(:"context_#{mode}")) }
        end

        f.group(hidden: true, data: effect_for("work_package")) do |group|
          group.select_list(
            name: :work_package_id,
            label: label(:work_package_label),
            caption: label(:work_package_caption),
            include_blank: true,
            data: target(:workPackageId)
          ) do |select|
            @work_packages.each do |work_package|
              select.option(value: work_package.id, label: work_package_label(work_package))
            end
          end
        end

        f.group(hidden: true, data: effect_for("new_work_package")) do |group|
          group.select_list(
            name: :project_id,
            label: label(:project_label),
            caption: label(:new_work_package_caption),
            include_blank: true,
            data: target(:projectId)
          ) do |select|
            @projects.each { |project| select.option(value: project.id, label: project.name) }
          end

          group.select_list(
            name: :type_id,
            label: label(:type_label),
            caption: label(:type_caption),
            include_blank: true,
            data: target(:typeId)
          ) do |select|
            @types.each { |type| select.option(value: type.id, label: type.name) }
          end
        end
      end

      def initialize(work_packages:, projects:, types:)
        super()
        @work_packages = work_packages
        @projects = projects
        @types = types
      end

      private

      def label(key)
        I18n.t("admin.text_transform_actions.sandbox.#{key}")
      end

      def work_package_label(work_package)
        "##{work_package.id} #{work_package.subject} (#{work_package.project.name}, #{work_package.type.name})"
      end

      def target(name)
        { ai_text_transform_sandbox_target: name }
      end

      def effect_for(mode)
        { show_when_value_selected_target: "effect", target_name: MODE_TARGET_NAME, value: mode }
      end
    end
  end
end
