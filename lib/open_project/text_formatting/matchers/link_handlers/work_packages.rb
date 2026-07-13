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

module OpenProject::TextFormatting::Matchers
  module LinkHandlers
    class WorkPackages < Base
      # CKEditor `#`-based mention triggers for WP references: `#N` plain link,
      # `##N` compact quickinfo, `###N` detailed quickinfo. Distinct from the
      # matcher's generic `sep` vocabulary (where `#` *separates* prefix from
      # id in `version#3`); here it's a sigil that triggers mention recognition.
      # Shared with the PDF-export subclass in `app/models/work_package/exports/macros/links.rb`.
      HASH_TRIGGERS = %w[# ## ###].freeze

      def applicable?
        hash_trigger? && matcher.prefix.nil?
      end

      # Examples: #1234, ##1234, ###1234, #PROJ-7, ##PROJ-7, ###PROJ-7
      def call
        identifier = matcher.identifier

        if WorkPackage::SemanticIdentifier.semantic_id?(identifier)
          # Semantic shapes are only meaningful in semantic mode; classic
          # instances render the literal text fallback.
          return nil unless Setting::WorkPackageIdentifier.semantic?

          render_for_semantic(identifier)
        else
          # Reject leading-zero shapes like `#0123` that aren't canonical id strings.
          return nil unless WorkPackage::SemanticIdentifier.numeric_id?(identifier)

          render_for_numeric(identifier.to_i)
        end
      end

      private

      def hash_trigger?
        HASH_TRIGGERS.include?(matcher.sep)
      end

      def quickinfo?
        matcher.sep.length > 1
      end

      def detailed?
        matcher.sep == "###"
      end

      def render_for_semantic(display_id)
        # Both quickinfo and plain link need the WP record so the rendered
        # HTML can carry the record id in `data-id`. Unresolved WP →
        # literal text rather than a broken reference.
        wp = preload_cache.fetch(display_id)
        return nil unless wp

        if quickinfo?
          render_work_package_macro(work_package: wp, fallback_id: display_id, detailed: detailed?)
        else
          render_work_package_link(wp, fallback_id: display_id)
        end
      end

      def render_for_numeric(wp_id)
        wp = preload_cache.fetch(wp_id)

        if quickinfo?
          render_work_package_macro(work_package: wp, fallback_id: wp_id, detailed: detailed?)
        else
          render_work_package_link(wp, fallback_id: wp_id)
        end
      end

      def render_work_package_macro(work_package:, fallback_id:, detailed: false)
        id = work_package&.id || fallback_id
        display_id = work_package&.display_id || fallback_id
        label = WorkPackage::SemanticIdentifier.format_display_id(display_id)

        return label if text_only?(work_package)
        return render_static_work_package_macro(work_package, label, detailed:) if context[:static_html]

        ApplicationController.helpers.content_tag "opce-macro-wp-quickinfo",
                                                  "",
                                                  data: { id:, display_id:, detailed: }
      end

      # The label keeps what the author wrote (possibly a historical
      # alias) so the rendered text matches the source markdown.
      def render_static_work_package_macro(work_package, label, detailed:)
        return label unless work_package

        link_to(OpenProject::TextFormatting::Helpers::StaticMacroLabel.call(work_package, label:, detailed:),
                work_package_path_or_url(id: work_package.display_id, only_path: context[:only_path]),
                class: "issue work_package")
      end

      def render_work_package_link(work_package, fallback_id:)
        # Fall back to the bare `#N` shape when no WP is provided (classic mode,
        # render path bypassing `PatternMatcherFilter`) rather than running a
        # per-link query inside the renderer.
        label = work_package&.formatted_id || "##{fallback_id}"
        return label if text_only?(work_package)

        href_id = work_package&.display_id || fallback_id

        link_to(label,
                work_package_path_or_url(id: href_id, only_path: context[:only_path]),
                class: "issue work_package",
                data: {
                  hover_card_trigger_target: "trigger",
                  hover_card_url: hover_card_work_package_path(href_id)
                })
      end

      # A nil WP means classic mode skipped the preload, or the reference
      # didn't resolve — neither case needs visibility gating.
      def text_only?(work_package)
        context[:plain_text] || (work_package && !preload_cache.visible?(work_package.id))
      end

      def preload_cache
        OpenProject::TextFormatting::Matchers::ResourceLinksMatcher.current_cache
      end
    end
  end
end
