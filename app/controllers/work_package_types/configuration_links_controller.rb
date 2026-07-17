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
  # TODO: This controller will be heavily refactored in the following PRs as we are switching to a modal approach
  class ConfigurationLinksController < BaseTabController
    include SubtypesFeature

    before_action :require_subtypes_feature

    current_menu_item do
      :types
    end

    # Linked: create/update the link to the chosen source.
    def update
      result = SwitchToLinkedModeService.new(type: @type, aspect: params[:aspect_id]).call(source:)

      if result.success?
        redirect_to tab_path_for(params[:aspect_id]), notice: I18n.t(:notice_successful_update)
      else
        redirect_to tab_path_for(params[:aspect_id]), alert: result.message
      end
    end

    # Independent: remove the link, adopting the picked source's config first.
    def destroy
      SwitchToIndependentModeService.new(type: @type, aspect: params[:aspect_id], user: current_user).call(source:)
      redirect_to tab_path_for(params[:aspect_id]), notice: I18n.t(:notice_successful_update)
    end

    private

    def source
      Type.global.find_by(id: source_id_param)
    end

    def source_id_param
      params.dig(:type_configuration_link, :source_id)
    end

    def tab_path_for(aspect)
      case aspect
      when Type::ConfigurationLink::PATTERNS
        edit_type_subject_configuration_path(type_id: @type.id)
      else
        edit_type_pdf_export_template_index_path(type_id: @type.id)
      end
    end
  end
end
