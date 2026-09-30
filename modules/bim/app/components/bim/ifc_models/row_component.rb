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

module Bim
  module IfcModels
    class RowComponent < ::RowComponent
      property :created_at

      def title
        if still_processing?
          model.title
        else
          link_to model.title,
                  bcf_project_ifc_model_path(model.project, model)
        end
      end

      def default?
        if model.is_default?
          helpers.op_icon "icon icon-checkmark"
        end
      end

      def updated_at
        helpers.format_date(model.updated_at)
      end

      def uploader
        icon = helpers.avatar model.uploader, size: :mini
        icon + model.uploader.name
      end

      def processing
        content_tag(:span) do
          content = ActiveSupport::SafeBuffer.new
          content << content_tag(:span,
                                 I18n.t("ifc_models.conversion_status.#{model.conversion_status}"),
                                 class: "ifc-models--conversion-status")

          if model.conversion_error_message
            content << ": "
            content << content_tag(:span,
                                   model.conversion_error_message,
                                   class: "ifc-models--conversion-status-error",
                                   title: model.conversion_error_message)
          end
          content
        end
      end

      def still_processing?
        model.xkt_attachment.nil?
      end

      ###

      def button_links
        links = []
        # Seeded IFC models currently actually only have the XKT and NOT(!) the IFC original seeded
        if model.ifc_attachment
          links << download_link
        end

        if User.current.allowed_in_project?(:manage_ifc_models, model.project)
          links.push(edit_link, delete_link)
        else
          links
        end
      end

      def delete_link
        link_to "",
                bcf_project_ifc_model_path(model.project, model),
                class: "icon icon-delete",
                data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) },
                title: I18n.t(:button_delete)
      end

      def download_link
        link_to "",
                API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(model.ifc_attachment&.id),
                class: "icon icon-download",
                title: I18n.t(:button_download),
                download: true
      end

      def edit_link
        link_to "",
                edit_bcf_project_ifc_model_path(model.project, model),
                class: "icon icon-edit",
                accesskey: helpers.accesskey(:edit),
                title: I18n.t(:button_edit)
      end
    end
  end
end
