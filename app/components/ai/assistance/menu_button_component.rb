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
  module Assistance
    # The AI Assistance menu in the app header (see HeaderButtonComponent): an icon button with
    # one section per assistant, headed by its name, and the user's history at the end. Empty
    # renders only the frame.
    class MenuButtonComponent < ApplicationComponent
      FRAME_ID = "wp-ai-assistance-menu"

      attr_reader :place, :skills

      def initialize(place:, skills: [], empty: false)
        super
        @place = place
        @skills = skills
        @empty = empty
      end

      def empty? = @empty

      # Personal assistants first, then group, then global ones. The order inside each kind is kept.
      def skills_by_assistant
        skills.group_by(&:assistant).sort_by.with_index { |(assistant, _), index| [owner_rank(assistant), index] }
      end

      # The assistant's name, then the icon of its owner kind (global, group, personal).
      def heading_title(assistant)
        icon = render(Primer::Beta::Octicon.new(icon: assistant.owner_icon, ml: 1, "aria-hidden": true))
        helpers.safe_join([assistant.name, icon])
      end

      # A chat skill opens its chat; any other starts a new conversation that it answers at once.
      def item_arguments(skill)
        if skill.chat?
          { href: url_helpers.ai_assistance_chat_path(**place.url_params, skill_id: skill.id),
            content_arguments: { data: { controller: "async-dialog", turbo_stream: true } } }
        else
          { href: url_helpers.start_ai_assistance_chat_path(place.url_params),
            form_arguments: { method: :post, inputs: [{ name: "skill_id", value: skill.id }] } }
        end
      end

      private

      def owner_rank(assistant)
        if assistant.personal? then 0
        elsif assistant.group? then 1
        else 2
        end
      end

      def history_path
        url_helpers.history_ai_assistance_chat_path(place.url_params)
      end
    end
  end
end
