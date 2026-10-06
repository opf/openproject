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

RSpec.describe "Forum topic thread", type: :rails_request, with_settings: { per_page_options: "2, 100" } do
  shared_let(:forum) { create(:forum) }
  shared_let(:reader) { create(:user, member_with_permissions: { forum.project => %i[view_messages] }) }
  shared_let(:topic) { create(:message, forum:, subject: "Release planning") }
  shared_let(:replies) { create_list(:message, 3, forum:, parent: topic) }

  current_user { reader }

  let(:html) { Capybara.string(response.body) }

  it "shows the whole thread on one page", :aggregate_failures do
    get project_forum_topic_path(forum.project, forum, topic)

    expect(html).to have_css("[data-test-selector^='forum-post-']", count: 4)
    expect(html).to have_no_css(".op-pagination")
  end

  it "shows the reply a link points to, however deep in the thread" do
    get project_forum_topic_path(forum.project, forum, topic, r: replies.last.id)

    expect(html).to have_css("#message-#{replies.last.id}")
  end
end
