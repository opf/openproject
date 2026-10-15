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

module API
  module V3
    module WorkPackages
      class PDFExportAPI < ::API::OpenProjectAPI
        TEMPLATE_PARAMS = {
          "attributes" => %i[footerText pageOrientation],
          "contract" => %i[headerTextRight footerTextCenter],
          "artefact" => %i[toc includeLifecycle includeBudget]
        }.freeze

        COMMON_PARAMS = %i[hyphenation hyphenationLanguage].freeze

        # Exporting a single work package needs no export permission, only the view permission
        # already enforced by the parent endpoint, as WorkPackagesController#generate_pdf does.
        resource :pdf do
          helpers do
            def pdf_export_templates
              @work_package.type_variant.pdf_export_templates
            end

            def requested_template
              template_id = declared_params[:template]
              return default_template if template_id.blank?

              template = pdf_export_templates.find(template_id)
              unless template&.enabled
                raise ::API::Errors::BadRequest,
                      I18n.t("api_v3.errors.bad_request.pdf_export_template_not_enabled", template: template_id)
              end

              template
            end

            def default_template
              pdf_export_templates.list_enabled.first ||
                raise(::API::Errors::BadRequest, I18n.t("api_v3.errors.bad_request.pdf_export_no_template_enabled"))
            end

            def export_options(template)
              permitted = TEMPLATE_PARAMS.fetch(template.id, []) + COMMON_PARAMS

              overrides = permitted.each_with_object({}) do |name, options|
                value = declared_params[name]
                options[name.to_s.underscore.to_sym] = value unless value.nil?
              end

              pdf_export_templates.settings_for(template.id).merge(overrides)
            end

            def respond_with_pdf(export)
              content_type export.mime_type
              header "Content-Disposition",
                     ActionDispatch::Http::ContentDisposition.format(disposition: "attachment", filename: export.title)
              header "X-Content-Type-Options", "nosniff"
              env["api.format"] = :binary

              export.content
            end
          end

          params do
            optional :template,
                     type: String,
                     values: -> { ::WorkPackage::PDFExport::Templates.built_in_templates.pluck(:id) },
                     desc: "The PDF export template to render. Defaults to the first one enabled for the work " \
                           "package's type."
            optional :footerText, type: String
            optional :pageOrientation, type: String, values: %w[portrait landscape]
            optional :headerTextRight, type: String
            optional :footerTextCenter, type: String
            optional :toc, type: Boolean
            optional :includeLifecycle, type: Boolean
            optional :includeBudget, type: Boolean
            optional :hyphenation, type: Boolean
            optional :hyphenationLanguage, type: String
          end

          get do
            template = requested_template
            export = template.exporter.new(@work_package, export_options(template)).export!

            respond_with_pdf(export)
          rescue ::Exports::ExportError => e
            raise ::API::Errors::InternalError.new(e.message, exception: e)
          end
        end
      end
    end
  end
end
