# frozen_string_literal: true

# -- copyright
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++
require "text/hyphen"

module WorkPackages
  module Exports
    module Generate
      class ModalDialogComponent < ApplicationComponent
        MODAL_ID = "op-work-package-generate-pdf-dialog"
        GENERATE_PDF_FORM_ID = "op-work-packages-generate-pdf-dialog-form"
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers
        include Templates::HyphenationOptions

        attr_reader :work_package, :params

        def initialize(work_package:, params:)
          super

          @work_package = work_package
          @params = params
        end

        def templates_default
          templates_options[0]
        end

        def templates_options
          work_package.type_variant.pdf_export_templates.list_enabled
        end

        def template_form_id(template_id)
          "#{GENERATE_PDF_FORM_ID}-#{template_id}"
        end

        def attributes_settings
          stored = template_settings("attributes")
          {
            footer_text: resolve_setting(stored, :footer_text, work_package.project.name),
            page_orientation: resolve_setting(stored, :page_orientation, "portrait"),
            hyphenation: resolve_boolean_setting(stored, :hyphenation, false),
            hyphenation_language: hyphenation_language_for(stored)
          }
        end

        def contract_settings
          stored = template_settings("contract")
          {
            footer_text_center: resolve_setting(stored, :footer_text_center, work_package.subject),
            hyphenation: resolve_boolean_setting(stored, :hyphenation, false),
            hyphenation_language: hyphenation_language_for(stored)
          }
        end

        def artefact_settings
          stored = template_settings("artefact")
          {
            toc: resolve_boolean_setting(stored, :toc, WorkPackage::PDFExport::Artefact::DEFAULT_TOC),
            include_lifecycle: resolve_boolean_setting(stored, :include_lifecycle,
                                                       WorkPackage::PDFExport::Artefact::DEFAULT_INCLUDE_LIFECYCLE),
            include_budget: resolve_boolean_setting(stored, :include_budget,
                                                    WorkPackage::PDFExport::Artefact::DEFAULT_INCLUDE_BUDGET),
            hyphenation: resolve_boolean_setting(stored, :hyphenation, false),
            hyphenation_language: hyphenation_language_for(stored)
          }
        end

        def hyphenation_default
          hyphenation_language_by_locale || hyphenation_options[0]
        end

        private

        def template_settings(template_id)
          work_package.type_variant.pdf_export_templates.settings_for(template_id)
        end

        # `stored` only ever has keys the admin explicitly saved (see
        # Type::PdfExportTemplates#settings_for), so `key?` - not `||` - is what tells "explicitly
        # set to a blank/false value" apart from "never configured, use today's default".
        def resolve_setting(stored, key, default)
          stored.key?(key) ? stored[key] : default
        end

        # Stored checkbox settings round-trip through the jsonb column as the strings "true"/
        # "false" (they arrive from a form submit). Rails' checked-state check
        # (ActionView::Helpers::Tags::Checkable#input_checked?) only treats the literal `true` or
        # the string "checked" as checked, so passing the stored string "true" straight through
        # would render the box unchecked. Cast the same way the exporters' own read sites already
        # do (e.g. WorkPackage::PDFExport::Artefact#with_toc?).
        def resolve_boolean_setting(stored, key, default)
          return default unless stored.key?(key)

          ActiveModel::Type::Boolean.new.cast(stored[key])
        end

        def hyphenation_language_for(stored)
          resolve_setting(stored, :hyphenation_language, nil) ||
            hyphenation_language_by_locale&.fetch(:value) ||
            hyphenation_options[0][:value]
        end
      end
    end
  end
end
