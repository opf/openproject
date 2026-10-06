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
      click_on "Quote"
    end

    expect(page).to have_css("#reply .ck-content", text: "wrote")
    expect(page).to have_css("#reply h2", text: "Reply", obscured: false)
    expect(page).to have_css("#reply :focus")
  end

  it "highlights a reply when following its link on the page" do
    reply = create(:message, forum:, parent: topic, subject: "RE: Release planning")
    show_page.visit!

    within_test_selector("forum-post-#{reply.id}") { click_link "RE: Release planning" }

    expect(page).to have_css("#message-#{reply.id}:target")
  end
end
