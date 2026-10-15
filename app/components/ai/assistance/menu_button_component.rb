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
    # one flat item per skill, the assistant's name as an inline label, and the user's history
    # at the end. Empty renders only the frame.
    class MenuButtonComponent < ApplicationComponent
      FRAME_ID = "wp-ai-assistance-menu"

      attr_reader :work_package, :skills

      def initialize(work_package:, skills: [], empty: false)
        super
        @work_package = work_package
        @skills = skills
        @empty = empty
      end

      def empty? = @empty

      def history_path
        url_helpers.history_work_package_ai_assistance_chat_path(work_package)
      end

      # A chat skill opens its chat; any other starts a new conversation that it answers at once.
      def item_arguments(skill)
        if skill.chat?
          { href: url_helpers.work_package_ai_assistance_chat_path(work_package, skill_id: skill.id),
            content_arguments: { data: { controller: "async-dialog", turbo_stream: true } } }
        else
          { href: url_helpers.start_work_package_ai_assistance_chat_path(work_package),
            form_arguments: { method: :post, inputs: [{ name: "skill_id", value: skill.id }] } }
        end
      end
    end
  end
end
