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

module AI
  # Demo only (AI-126): renders the shell of the AI action menu that the description
  # editor mounts next to its toolbar. The actions themselves come from the
  # API v3 list endpoints (AI-134), which also check the permissions.
  class TextTransformMenusController < ApplicationController
    FRAME_ID = /\Aai-text-transform-menu-[a-z0-9]+\z/

    no_authorization_required! :show

    layout false

    def show
      return head(:unauthorized) unless current_user.logged?
      return head(:bad_request) unless FRAME_ID.match?(params[:frame_id].to_s)

      render(AI::TextTransforms::MenuComponent.new(frame_id: params[:frame_id], list_url:, context: context_params))
    end

    private

    def context_params
      params.permit(:work_package_id, :project_id, :type_id).to_h.transform_values(&:to_i).select { |_, id| id.positive? }
    end

    def api_v3_paths = API::V3::Utilities::PathHelper::ApiV3Path

    def list_url
      context = context_params

      if context["work_package_id"]
        api_v3_paths.ai_text_transform_actions_by_work_package(context["work_package_id"])
      elsif context["project_id"] && context["type_id"]
        api_v3_paths.ai_text_transform_actions_by_project(context["project_id"], type_id: context["type_id"])
      else
        api_v3_paths.ai_text_transform_actions
      end
    end
  end
end
