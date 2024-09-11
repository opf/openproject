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
      expect(page).to have_css(".title-container", text: subject)
    end

    def expect_content(content)
      expect(page).to have_css(".forum-message .wiki", text: content)
    end

    def expect_no_replies
      expect(page).to have_no_content("Replies")
    end

    def expect_num_replies(num)
      expect(page).to have_content("Replies (#{num})")
    end

    def reply(text)
      find(".ck-content").base.send_keys text

      click_button "Submit"

      expect(page).to have_css(".forum-message--comments", text:)

      Message.last
    end

    def quote(content:, quoted_message: nil, subject: nil)
      if quoted_message
        within "#message-#{quoted_message.id} .contextual" do
          click_on "Quote"
        end
      else
        within ".toolbar-items" do
          click_on "Quote"
        end
      end

      sleep 1

      scroll_to_element find(".ck-content")
      fill_in "reply_subject", with: subject if subject

      editor = find(".ck-content")
      editor.base.send_keys content

      # For some reason, capybara will click on
      # the button to add another attachment when being told to click on "Submit".
      # Therefor, submitting by enter key.
      subject_field = find_by_id("reply_subject")
      subject_field.native.send_keys(:return)

      text = (quoted_message || Message.first).content
      expect(page).to have_css(".forum-message--comments blockquote", text:)

      Message.last
    end

    def expect_reply(subject:, content:, reply: nil)
      selector = ".comment"
      selector += "#message-#{reply.id}" if reply

      within(selector) do
        expect(page).to have_content(subject)
        expect(page).to have_content(content)
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
      topic_path(message)
    end
  end
end
