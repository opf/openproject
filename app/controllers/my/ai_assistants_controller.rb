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

module My
  # The user's own assistants. They show only in the user's AI Assistance menu, and they
  # use the default model of the LLM connection.
  class AIAssistantsController < ::ApplicationController
    before_action :require_login
    before_action :authorize_global

    # After the access checks: the shared actions look up records.
    include AIAssistance::AssistantsActions

    menu_item :ai_assistants

    layout "my"

    private

    def assistant_scope
      AI::Assistant.where(principal: current_user)
    end

    def new_assistant(attributes = {})
      AI::Assistant.new(attributes.merge(principal: current_user))
    end

    def assistant_params
      params.expect(ai_assistant: %i[name description instructions icon active])
    end
  end
end
