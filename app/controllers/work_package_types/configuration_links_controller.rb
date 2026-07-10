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
  class ConfigurationLinksController < ApplicationController
    layout "admin"

    before_action :require_admin
    before_action :find_type

    current_menu_item do
      :types
    end

    def update
      result = SetConfigurationLinkService
                 .new(type: @type, aspect: params[:aspect])
                 .call(mode: params[:mode], source_id: params[:source_id])

      message = result.success? ? { notice: I18n.t(:notice_successful_update) } : { alert: result.message }
      redirect_to tab_path_for(params[:aspect]), **message
    end

    private

    def find_type
      @type = ::Type.find(params.expect(:type_id))
    end

    def tab_path_for(aspect)
      case aspect
      when Type::ConfigurationLink::SUBJECT
        edit_type_subject_configuration_path(type_id: @type.id)
      else
        edit_type_pdf_export_template_index_path(type_id: @type.id)
      end
    end
  end
end
