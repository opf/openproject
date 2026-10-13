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
  module AssistantChats
    # Stores the user's question and a pending answer, and starts the reply job. One
    # answer at a time: a question while an answer is pending is refused.
    class SendMessageService
      MAX_LENGTH = 10_000

      attr_reader :chat, :user

      def initialize(chat:, user:)
        @chat = chat
        @user = user
      end

      def call(content)
        content = content.to_s.strip
        return ServiceResult.failure(message: I18n.t("ai_assistance.chat.errors.empty")) if content.empty?
        return ServiceResult.failure(message: I18n.t("ai_assistance.chat.errors.pending")) if chat.pending?

        answer = AI::AssistantChat.transaction do
          chat.messages.create!(role: "user", content: content.truncate(MAX_LENGTH))
          chat.messages.create!(role: "assistant", status: "pending", locale: I18n.locale.to_s,
                                base_lock_version: chat.work_package.reload.lock_version)
        end
        ReplyJob.perform_later(answer.id)
        ServiceResult.success(result: answer)
      end
    end
  end
end
