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

module Admin
  class AIAssistantsController < ::ApplicationController
    before_action :require_admin

    # After the access checks: the shared actions look up records.
    include AIAssistance::AssistantsActions

    menu_item :ai_assistants

    layout "admin"

    private

    # All assistants, global and owned.
    def assistant_scope
      AI::Assistant.includes(:principal)
    end

    # An admin creates a global assistant, or one for a group. The owner never changes.
    def new_assistant(attributes = {})
      AI::Assistant.new(attributes.merge(principal: chosen_group))
    end

    def chosen_group
      id = params.dig(:ai_assistant, :principal_id).presence
      Group.find_by(id:) if id
    end

    def assistant_params
      params.expect(ai_assistant: %i[name description instructions model_id active])
    end
  end
end
