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
          template_settings("attributes")
        end

        def contract_settings
          template_settings("contract")
        end

        def artefact_settings
          template_settings("artefact")
        end

        def hyphenation_default
          hyphenation_language_by_locale || hyphenation_options[0]
        end

        private

        def template_settings(template_id)
          work_package.type_variant.pdf_export_templates.settings_with_defaults_for(template_id, work_package)
        end
      end
    end
  end
end
