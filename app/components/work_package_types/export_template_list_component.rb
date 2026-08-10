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
  class ExportTemplateListComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    def initialize(variant:, readonly: false)
      super

      @variant = variant
      @readonly = readonly
    end

    def readonly? = @readonly

    def wrapper_data_attributes
      return {} if @readonly

      {
        controller: "generic-drag-and-drop"
      }
    end

    def drag_and_drop_target_config
      {
        generic_drag_and_drop_target: "container",
        target_container_accessor: ":scope > ul",
        target_allowed_drag_type: "template",
        test_selector: "pdf-export-template-rows"
      }
    end

    def draggable_item_config(template)
      {
        draggable_id: template.id,
        draggable_type: "template",
        drop_url: drop_type_pdf_export_template_path(**@variant.path_args, id: template.id),
        test_selector: "pdf-export-template-row-#{template.id}"
      }
    end
  end
end
