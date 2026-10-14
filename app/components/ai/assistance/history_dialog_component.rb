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
    # The user's chats on this work package, newest first.
    class HistoryDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      DIALOG_ID = "ai-assistance-history-dialog"

      attr_reader :work_package

      def initialize(work_package:, chats:)
        super
        @work_package = work_package
        @chats = chats.to_a.select { |chat| chat.messages.any? }
      end

      def entries
        @chats.sort_by(&:created_at).reverse
      end

      def entry_path(chat)
        url_helpers.work_package_ai_assistance_chat_path(work_package, chat_id: chat.id)
      end

      # A chat also shows its first question. A skill that answers at once asks its own label.
      def entry_label(chat)
        return chat.skill.full_label unless chat.skill.chat?

        "#{chat.skill.full_label} · #{chat.messages.find(&:from_user?)&.content.to_s.truncate(60)}"
      end

      def entry_detail(chat)
        I18n.t("ai_assistance.history.questions", count: chat.messages.count(&:from_user?))
      end

      def entry_icon(chat)
        chat.skill.icon
      end
    end
  end
end
