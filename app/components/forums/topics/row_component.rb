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

module Forums
  module Topics
    class RowComponent < OpPrimer::BorderBoxRowComponent
      alias_method :topic, :model

      delegate :project, :forum, to: :table
      delegate :replies_count, to: :topic

      def row_data = { test_selector: "topic-row-#{topic.id}" }

      def subject
        safe_join([subject_line, preview])
      end

      def author
        helpers.primer_link_to_user(topic.author) if topic.author
      end

      def created_at = helpers.format_time(topic.created_at)

      def last_reply
        reply = topic.last_reply
        return if reply.nil?

        time = render(Primer::Beta::Link.new(href: reply_path(reply), underline: false)) { helpers.format_time(reply.created_at) }
        safe_join([reply.author&.name, time].compact, " · ")
      end

      private

      def reply_path(reply)
        project_forum_topic_path(project, forum, topic, r: reply.id, anchor: "message-#{reply.id}")
      end

      def subject_line
        flex_layout(align_items: :center) do |flex|
          flex.with_column(mr: 1) { flag(:pin, I18n.t("js.label_board_sticky"), "topic-sticky") } if topic.sticky?
          flex.with_column(mr: 1) { flag(:lock, I18n.t("js.label_board_locked"), "topic-locked") } if topic.locked?
          flex.with_column(classes: "ellipsis") { subject_link }
        end
      end

      def preview
        render(Primer::Beta::Text.new(tag: :div, mt: 1, pr: 4, color: :muted, font_size: :small, classes: "ellipsis",
                                      test_selector: "topic-preview")) do
          helpers.truncate_formatted_text(topic.content, length: 200, replace_newlines: false)
        end
      end

      def subject_link
        render(Primer::Beta::Link.new(href: project_forum_topic_path(project, forum, topic), underline: false)) do
          render(Primer::Beta::Text.new(font_weight: :bold)) { topic.subject }
        end
      end

      def flag(icon, label, test_selector)
        render(Primer::Beta::Octicon.new(icon:, "aria-label": label, test_selector:))
      end
    end
  end
end
