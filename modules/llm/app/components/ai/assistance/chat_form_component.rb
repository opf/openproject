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
    # The footer of the chat dialog: the question field, and the buttons to start a new
    # chat, send, and close. One form, so the footer has no empty form below the buttons.
    class ChatFormComponent < ApplicationComponent
      include OpTurbo::Streamable

      attr_reader :place, :skill, :chat, :dialog_id, :read_only

      def initialize(place:, skill:, chat:, dialog_id:, read_only: false)
        super
        @place = place
        @skill = skill
        @chat = chat
        @dialog_id = dialog_id
        @read_only = read_only
      end

      def self.wrapper_key = "ai-assistance-chat-form"

      def pending?
        chat&.pending?
      end

      def send_path
        url_helpers.messages_ai_assistance_chat_path(place.url_params)
      end

      def new_chat_path
        url_helpers.ai_assistance_chat_path(place.url_params)
      end

      def placeholder
        if place.work_package? then I18n.t("ai_assistance.chat.placeholder", id: place.label)
        else I18n.t("ai_assistance.chat.placeholder_generic")
        end
      end

      def rerun?
        chat.present? && !skill.chat?
      end

      def rerun_path
        url_helpers.rerun_ai_assistance_chat_path(place.url_params)
      end
    end
  end
end
