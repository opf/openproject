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

module Documents
  class Menu < Submenu
    attr_reader :project, :params

    def initialize(project: nil, params: nil)
      super(view_type: nil, project:, params:)
    end

    def menu_items
      [menu_group(header: nil, children: document_status_options),
       menu_group(header: I18n.t("documents.menu.types"), children: document_type_options)]
    end

    def document_status_options
      [menu_item(title: I18n.t("documents.menu.all"), selected: params[:filters].blank?)]
    end

    def document_type_options
      @document_type_options ||= menu_item_filter_for(DocumentType, :type_id)
    end

    def query_path(query_params)
      project_documents_path(project, query_params)
    end

    private

    def menu_item_filter_for(model_class, filter_id)
      model_class.pluck(:id, :name).map do |id, title|
        filters = [{ filter_id => { operator: "=", values: [id.to_s] } }].to_json
        menu_item(title:, query_params: { filters: })
      end
    end
  end
end
