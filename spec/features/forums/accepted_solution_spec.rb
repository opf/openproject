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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Accepting a forum reply as solution", :js do
  shared_let(:forum) { create(:forum) }
  shared_let(:topic_author) { create(:user, member_with_permissions: { forum.project => %i[view_messages add_messages] }) }
  shared_let(:replier) { create(:user, firstname: "Bob", lastname: "Replier") }
  shared_let(:topic) { create(:message, forum:, author: topic_author, subject: "Release planning") }
  shared_let(:reply) { create(:message, forum:, parent: topic, author: replier, content: "Ship on Friday") }

  let(:show_page) { Pages::Messages::Show.new(topic) }

  before { login_as(topic_author) }

  it "lets the topic's author accept a reply, follow the banner to it and unaccept it", :aggregate_failures do
    show_page.visit!

    within_test_selector("forum-post-#{reply.id}") do
      click_on accessible_name: "Message actions"
      click_on "Accept as solution"
    end

    expect(page).to have_css("#message-#{reply.id}:focus")
    expect(page).to have_test_selector("accepted-solutions-banner", text: "Accepted solution: Bob Replier")
    expect(find_test_selector("topic-summary")).to have_role(:img, accessible_name: "With accepted solution")
    expect(find_test_selector("forum-post-#{reply.id}")).to have_role(:img, accessible_name: "Accepted solution")

    within_test_selector("accepted-solutions-banner") { click_on "Bob Replier" }
    expect(page).to have_css("#message-#{reply.id}:target")

    within_test_selector("forum-post-#{reply.id}") do
      click_on accessible_name: "Message actions"
      click_on "Remove as solution"
    end

    expect(page).to have_no_test_selector("accepted-solutions-banner")
    expect(find_test_selector("topic-summary")).to have_no_role(:img, accessible_name: "With accepted solution")
  end
end
