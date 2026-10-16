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
    class TableComponent < ::TableComponent
      columns :title, :default?, :created_at, :updated_at, :uploader, :processing

      def initial_sort
        %i[created_at asc]
      end

      def sortable?
        false
      end

      def inline_create_link
        link_to(new_bcf_project_ifc_model_path,
                class: "wp-inline-create--add-link",
                title: I18n.t("ifc_models.label_new_ifc_model")) do
          helpers.op_icon("icon icon-add")
        end
      end

      def empty_row_message
        I18n.t "ifc_models.no_results"
      end

      def headers
        [
          ["title", { caption: IfcModel.human_attribute_name(:title) }],
          ["is_default", { caption: IfcModel.human_attribute_name(:is_default) }],
          ["created_at", { caption: IfcModel.human_attribute_name(:created_at) }],
          ["updated_at", { caption: IfcModel.human_attribute_name(:updated_at) }],
          ["uploader", { caption: IfcModel.human_attribute_name(:uploader) }],
          ["processing", { caption: I18n.t("ifc_models.conversion_status.label") }]
        ]
      end
    end
  end
end
