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

module WorkPackageTypes
  module Overview
    class RowComponent < OpPrimer::BorderBoxRowComponent
      delegate :variant, to: :table

      def row_css_id = "overview-#{tab[:name]}"

      def setting
        render(Primer::Beta::Link.new(href: tab[:path], font_weight: :bold)) { helpers.tab_label(tab) }
      end

      def configuration_mode
        return muted(t("types.edit.overview.mode.always_manual")) if aspect.nil?
        return muted(t("types.edit.overview.mode.manual")) unless variant.linked?(aspect)

        t("types.edit.overview.mode.inheriting_from_html", source_name:)
      end

      def dependents
        return muted("-") if dependents_count.zero?

        render(Primer::Beta::Link.new(href: dependents_dialog_path,
                                      data: { controller: "async-dialog" })) do
          t("types.edit.reuse_mode.dependents.title", count: dependents_count)
        end
      end

      private

      def tab = model

      # fetch, so a tab added to TypesHelper#types_tabs without an aspect fails loudly here
      # rather than silently claiming to be always manual.
      def aspect = tab.fetch(:aspect)

      def source = variant.source_for(aspect)

      def source_name
        return bold(source.composite_name) unless source_reachable?

        render(Primer::Beta::Link.new(href: helpers.aspect_edit_path(source, aspect), font_weight: :bold)) do
          source.composite_name
        end
      end

      # A project's own variant may only borrow from that project, so a source outside it
      # belongs to administration and is named without a link the reader could not follow.
      def source_reachable?
        return true if helpers.variant_scope_project.nil?

        source.project_id == helpers.variant_scope_project.id
      end

      def dependents_count
        @dependents_count ||= aspect.nil? ? 0 : variant.dependents_for(aspect).count(:all)
      end

      def dependents_dialog_path
        type_configuration_dependents_dialog_path(**variant.path_args, aspect:)
      end

      def muted(text) = render(Primer::Beta::Text.new(color: :muted)) { text }

      def bold(text) = render(Primer::Beta::Text.new(font_weight: :bold)) { text }
    end
  end
end
