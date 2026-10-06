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

require "support/pages/messages/base"

module Pages::Messages
  class Show < Pages::Messages::Base
    attr_accessor(:message)

    def initialize(message)
      self.message = message
    end

    def expect_subject(subject)
      expect(page).to have_css(".PageHeader-title", text: subject)
    end

    def expect_content(content)
      within_test_selector("forum-post-#{message.id}") do
        expect(page).to have_css(".op-uc-container", text: content)
      end
    end

    def expect_no_replies
      expect(page).to have_test_selector("topic-summary", text: "No replies yet")
    end

    def expect_num_replies(num)
      expect(page).to have_test_selector("topic-summary", text: num == 1 ? "1 reply" : "#{num} replies")
    end

    def reply(text)
      find("#reply .ck-content").base.send_keys text

      click_button "Reply"

      expect(page).to have_css("[data-test-selector^='forum-post-']", text:)

      Message.last
    end

    def quote(content:, quoted_message: nil)
      if quoted_message
        within_test_selector("forum-post-#{quoted_message.id}") do
          click_on accessible_name: "Message actions"
          click_on "Quote"
        end
      else
        within_test_selector("forum-post-#{message.id}") do
          click_on accessible_name: "Message actions"
          click_on "Quote"
        end
      end

      sleep 1

      editor = find("#reply .ck-content")
      editor.base.send_keys content

      click_button "Reply"

      text = (quoted_message || Message.first).content
      expect(page).to have_css("[data-test-selector^='forum-post-'] blockquote", text:)

      Message.last
    end

    def expect_reply(content:, reply: nil)
      card = reply ? find_test_selector("forum-post-#{reply.id}") : all("[data-test-selector^='forum-post-']").last

      within(card) do
        expect(page).to have_text(content)
      end
    end

    def expect_current_path(reply = nil)
      replies_to = reply ? "r=#{reply.id}" : nil
      super(replies_to)
    end

    def click_save
      click_button "Save"
    end

    def path
      project_forum_topic_path(message.forum.project, message.forum, message)
    end
  end
end
