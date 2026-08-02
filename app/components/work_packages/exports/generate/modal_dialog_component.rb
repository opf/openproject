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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
        attr_reader :work_package, :params

        def initialize(work_package:, params:)
          super

          @work_package = work_package
          @params = params
        end

        def default_footer_text_center
          work_package.subject
        end

        def default_footer_text
          work_package.project.name
        end

        def templates_default
          templates_options[0]
        end

        def templates_options
          work_package.type.pdf_export_templates.list_enabled
        end

        def hyphenation_default
          hyphenation_language_by_locale || hyphenation_options[0]
        end

        def page_orientation_default
          page_orientation_options[0]
        end

        def page_orientation_options
          [
            { label: I18n.t("pdf_generator.dialog.page_orientation.options.portrait"), value: "portrait" },
            { label: I18n.t("pdf_generator.dialog.page_orientation.options.landscape"), value: "landscape" }
          ]
        end

        def hyphenation_language_by_locale
          search_locale = I18n.locale.to_s
          hyphenation_options.find { |lang| lang[:value] == search_locale }
        end

        def hyphenation_options
          # This is a list of languages that are supported by the hyphenation library
          # https://rubygems.org/gems/text-hyphen
          # The labels are the language names in the language itself (NOT to be put I18n)
          [
            { label: "-", value: "" },
            { label: "Català", value: "ca" },
            { label: "Dansk", value: "da" },
            { label: "Deutsch", value: "de" },
            { label: "Eesti", value: "et" },
            { label: "English", value: "en" },
            { label: "Español", value: "es" },
            { label: "Euskara", value: "eu" },
            { label: "Français", value: "fr" },
            { label: "Gaeilge", value: "ga" },
            { label: "Hrvatski", value: "hr" },
            { label: "Indonesia", value: "id" },
            { label: "Interlingua", value: "ia" },
            { label: "Italiano", value: "it" },
            { label: "Magyar", value: "hu" },
            { label: "Melayu", value: "ms" },
            { label: "Nederlands", value: "nl" },
            { label: "Norsk", value: "no" },
            { label: "Polski", value: "pl" },
            { label: "Português", value: "pt" },
            { label: "Slovenčina", value: "sk" },
            { label: "Suomi", value: "fi" },
            { label: "Svenska", value: "sv" },
            { label: "Ísland", value: "is" },
            { label: "Čeština", value: "cs" },
            { label: "Монгол", value: "mn" },
            { label: "Русский", value: "ru" }
          ]
        end
      end
    end
  end
end
