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
    # The conversation in the dialog body. Replaced after each question, and polled while
    # an answer is pending.
    class ChatComponent < ApplicationComponent
      include OpTurbo::Streamable
      include Polling

      attr_reader :work_package, :skill, :chat

      def initialize(work_package:, skill:, chat:)
        super
        @work_package = work_package
        @skill = skill
        @chat = chat
      end

      def self.wrapper_key = "ai-assistance-chat"

      def messages
        chat ? chat.messages.includes(:proposals).to_a : []
      end

      def pending?
        chat&.pending?
      end

      def wrapper_data
        pending? ? poll_data(url_helpers.poll_work_package_ai_assistance_chat_path(work_package, chat_id: chat.id)) : {}
      end

      def read_only?
        skill.scope_read_only?
      end

      def start_text
        I18n.t("ai_assistance.chat.started", user: chat.user.name, skill: skill.display_label)
      end

      def pending_text(previous)
        key = previous&.from_start? ? "working_on" : "answering"
        I18n.t("ai_assistance.chat.#{key}", assistant: skill.assistant.name, id: work_package.formatted_id)
      end
    end
  end
end
