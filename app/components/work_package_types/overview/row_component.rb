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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module Overview
    class RowComponent < OpPrimer::BorderBoxRowComponent
      delegate :variant, to: :table

      WORKFLOW_TAB = "workflow"

      def row_css_id = "overview-#{tab[:name]}"

      def setting
        render(Primer::Beta::Link.new(href: tab[:path], font_weight: :bold)) { helpers.tab_label(tab) }
      end

      def configuration_mode
        return form_configuration_mode if tab[:name] == TypeVariant::FORM_CONFIGURATION
        return workflow_mode if tab[:name] == WORKFLOW_TAB
        return muted_mode("always_manual") if aspect.nil?
        return muted_mode("manual") unless variant.linked?(aspect)

        t("types.edit.overview.mode.inheriting_from_html", source_name:)
      end

      private

      def tab = model

      # fetch, so a tab added to TypesHelper#types_tabs without an aspect fails loudly here
      # rather than silently claiming to be always manual.
      def aspect = tab.fetch(:aspect)

      def source = variant.source_for(aspect)

      def source_name
        reference_link(source.composite_name, helpers.aspect_edit_path(source, aspect), reachable: reachable?(source))
      end

      def form_configuration_mode
        named_reference_mode(variant.form_configuration, "using_form_html") do |form|
          helpers.edit_form_configuration_path(form)
        end
      end

      def workflow_mode
        named_reference_mode(variant.workflow, "using_workflow_html") do |workflow|
          helpers.edit_workflow_path(workflow)
        end
      end

      def named_reference_mode(reference, key)
        t("types.edit.overview.mode.#{key}", name: reference_link(reference.name, yield(reference), reachable: admin_context?))
      end

      def muted_mode(key) = muted(t("types.edit.overview.mode.#{key}"))

      def reference_link(label, path, reachable:)
        return bold(label) unless reachable

        render(Primer::Beta::Link.new(href: path, font_weight: :bold)) { label }
      end

      def admin_context? = helpers.variant_scope_project.nil?

      # A project's own variant may only borrow from that project, so a source outside it
      # belongs to administration and is named without a link the reader could not follow.
      def reachable?(source_record)
        admin_context? || source_record.project_id == helpers.variant_scope_project.id
      end

      def muted(text) = render(Primer::Beta::Text.new(color: :muted)) { text }

      def bold(text) = render(Primer::Beta::Text.new(font_weight: :bold)) { text }
    end
  end
end
