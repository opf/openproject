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
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :subject, :author, :created_at, :replies_count, :last_reply
      main_column :subject, :last_reply
      mobile_columns :subject

      options :forum

      delegate :project, to: :forum

      def headers
        [
          [:subject, { caption: Message.human_attribute_name(:subject) }],
          [:author, { caption: Message.human_attribute_name(:author) }],
          [:created_at, { caption: Message.human_attribute_name(:created_at) }],
          [:replies_count, { caption: I18n.t(:label_reply_plural) }],
          [:last_reply, { caption: I18n.t(:label_message_last) }]
        ]
      end

      def mobile_title = I18n.t(:label_topic_plural)

      def container_id = "forum-topics-table"

      def blank_icon = :"comment-discussion"

      def blank_title = I18n.t("forums.show.no_results_title_text")

      def blank_description = nil
    end
  end
end
