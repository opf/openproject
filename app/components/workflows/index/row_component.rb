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

module Workflows
  module Index
    class RowComponent < OpPrimer::BorderBoxRowComponent
      def name
        safe_join([title, created_in, description].compact)
      end

      def types_and_variants
        return dash if variants.empty?

        text(types_and_variants_label)
      end

      def roles
        return dash if role_count.zero?

        text(t("workflows.index.roles_count", count: role_count))
      end

      def projects
        return dash if project_count.zero?

        text(t("workflows.index.projects_count", count: project_count))
      end

      def button_links
        [render(RowActionsComponent.new(workflow:))]
      end

      private

      def workflow = model

      def variants = @variants ||= table.variants_for(workflow)

      def role_count = @role_count ||= table.role_count_for(workflow)

      def description
        return if workflow.description.blank?

        render(Primer::Beta::Text.new(tag: :div, font_size: :small, color: :muted)) { workflow.description }
      end

      def created_in
        project = workflow.project
        return if project.nil?

        link = render(Primer::Beta::Link.new(href: helpers.project_settings_work_packages_types_path(project))) do
          project.name
        end

        render(Primer::Beta::Text.new(tag: :div, font_size: :small, color: :muted)) do
          t("types.edit.variants.created_in_html", project: link)
        end
      end

      def types_and_variants_label
        types = t("workflows.index.types_count", count: variants.map(&:type_id).uniq.size)
        named = variants.count { !it.is_default_variant? }
        return types if named.zero?

        t("workflows.index.types_and_variants_count",
          types:,
          variants: t("workflows.index.variants_count", count: named))
      end

      def project_count
        @project_count ||= variants.flat_map { |variant| variant.projects.map(&:id) }.uniq.size
      end

      def title
        render(Primer::Beta::Link.new(href: helpers.edit_workflow_path(workflow),
                                      font_weight: :bold)) { workflow.name }
      end

      def text(content) = render(Primer::Beta::Text.new) { content }

      def dash = render(Primer::Beta::Text.new(color: :muted)) { "-" }
    end
  end
end
