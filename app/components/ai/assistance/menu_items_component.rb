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
    # The deferred list of the AI Assistance menu: one flat item per skill, with the
    # assistant's name as an inline label, and the user's history at the end.
    class MenuItemsComponent < ApplicationComponent
      attr_reader :work_package, :skills

      def initialize(work_package:, skills:)
        super
        @work_package = work_package
        @skills = skills
      end

      def menu_id = MenuButtonComponent::MENU_ID

      def chat_path(skill)
        url_helpers.work_package_ai_assistance_chat_path(work_package, skill_id: skill.id)
      end

      def start_path
        url_helpers.start_work_package_ai_assistance_chat_path(work_package)
      end

      def runs_path
        url_helpers.work_package_ai_assistance_runs_path(work_package)
      end

      # A chat opens its dialog; a custom prompt starts a conversation; other skills start a run.
      def item_arguments(skill)
        if skill.chat?
          { href: chat_path(skill), content_arguments: { data: { controller: "async-dialog", turbo_stream: true } } }
        else
          { href: skill.conversation? ? start_path : runs_path,
            form_arguments: { method: :post, inputs: [{ name: "skill_id", value: skill.id }] } }
        end
      end
    end
  end
end
