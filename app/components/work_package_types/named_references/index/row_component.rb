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
  module NamedReferences
    module Index
      class RowComponent < OpPrimer::BorderBoxRowComponent
        delegate :kind, to: :table

        def name
          safe_join([title, created_in, description].compact)
        end

        def types_and_variants
          return dash if variants.empty?

          text(types_and_variants_label)
        end

        def projects
          return dash if project_count.zero?

          text(kind.t("index.projects_count", count: project_count))
        end

        def button_links
          [render(RowActionsComponent.new(record:, kind:))]
        end

        private

        def record = model

        def variants = @variants ||= table.variants_for(record)

        def description
          return if record.description.blank?

          render(Primer::Beta::Text.new(tag: :div, font_size: :small, color: :muted)) { record.description }
        end

        def created_in
          project = kind.project_owned && record.project
          return if project.blank?

          link = render(Primer::Beta::Link.new(href: helpers.project_settings_work_packages_types_path(project))) do
            project.name
          end

          render(Primer::Beta::Text.new(tag: :div, font_size: :small, color: :muted)) do
            t("types.edit.variants.created_in_html", project: link)
          end
        end

        def types_and_variants_label
          types = kind.t("index.types_count", count: variants.map(&:type_id).uniq.size)
          named = variants.count { !it.is_default_variant? }
          return types if named.zero?

          kind.t("index.types_and_variants_count", types:, variants: kind.t("index.variants_count", count: named))
        end

        def project_count
          @project_count ||= variants.flat_map { |variant| variant.projects.map(&:id) }.uniq.size
        end

        def title
          render(Primer::Beta::Link.new(href: helpers.edit_polymorphic_path(record), font_weight: :bold)) { record.name }
        end

        def text(content) = render(Primer::Beta::Text.new) { content }

        def dash = render(Primer::Beta::Text.new(color: :muted)) { "-" }
      end
    end
  end
end
