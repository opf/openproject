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

require "spec_helper"

RSpec.describe "Forum topic page", :js do
  shared_let(:forum) { create(:forum) }
  shared_let(:user) { create(:user, member_with_permissions: { forum.project => %i[view_messages add_messages] }) }
  shared_let(:topic) do
    create(:message, forum:, subject: "Release planning", content: (1..80).map { "Paragraph #{it}" }.join("\n\n"))
  end

  let(:show_page) { Pages::Messages::Show.new(topic) }

  before { login_as(user) }

  it "brings the reply box into view with the quote ready to edit", :aggregate_failures do
    show_page.visit!

    within_test_selector("forum-post-#{topic.id}") do
      click_on accessible_name: "Message actions"
      click_on "Quote message"
    end

    expect(page).to have_css("#reply .ck-content", text: "wrote")
    expect(page).to have_css("#reply .ck-toolbar", obscured: false)
    expect(page).to have_css("#reply :focus")
  end

  it "highlights a reply when following its link on the page" do
    reply = create(:message, forum:, parent: topic, subject: "RE: Release planning")
    show_page.visit!

    within_test_selector("forum-post-#{reply.id}") { find("a[href$='#message-#{reply.id}']").click }

    expect(page).to have_css("#message-#{reply.id}:target")
  end

  context "with a long thread" do
    let!(:replies) do
      Array.new(45) do |i|
        create(:message, forum:, parent: topic, content: "Reply #{i + 1}", created_at: topic.created_at + (i + 1).minutes)
      end
    end

    it "loads the hidden replies a page at a time, back from the latest ones", :aggregate_failures do
      show_page.visit!
      url = page.current_url

      show_page.within_gap { click_on "Load previous 20 replies (out of 25)" }
      expect(page).to have_css("#message-#{replies[5].id}")
      expect(page).to have_no_css("#message-#{replies[4].id}")
      expect(page).to have_link("Load previous 5 replies", focused: true)

      show_page.within_gap { click_on "Load previous 5 replies" }
      expect(page).to have_css("#message-#{replies[0].id}:focus")
      show_page.expect_no_gap
      expect(page).to have_css("[data-test-selector^='forum-post-']", count: 46)

      expect(page.current_url).to eq(url)
    end

    it "highlights a hidden reply a link points to" do
      visit project_forum_topic_path(forum.project, forum, topic, r: replies[10].id, anchor: "message-#{replies[10].id}")

      expect(page).to have_css("#message-#{replies[10].id}:target")
    end
  end
end
