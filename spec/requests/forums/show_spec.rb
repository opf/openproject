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

RSpec.describe "Forum topic list", type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:reader) { create(:user, member_with_permissions: { project => %i[view_messages] }) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:busy) { create(:message, forum:, subject: "Busy topic") }
  shared_let(:quiet) { create(:message, forum:, subject: "Quiet topic") }
  shared_let(:pinned) { create(:message, forum:, subject: "Pinned topic", sticky: true) }

  current_user { reader }

  before { busy.update_column(:replies_count, 5) }

  def listed_subjects
    Capybara.string(response.body).all("[data-test-selector^='topic-row-'] .subject").map { it.text.strip }
  end

  def checked_sort
    Capybara.string(response.body)
            .find(:test_id, "forum-topics-sort", visible: :all)
            .find("[aria-checked='true']", visible: :all)
            .text.strip
  end

  it "keeps sticky topics first whatever the requested order" do
    get project_forum_path(project, forum, sort: "replies:desc")

    expect(listed_subjects).to eq(["Pinned topic", "Busy topic", "Quiet topic"])
  end

  it "checks the requested order in the Sort menu" do
    get project_forum_path(project, forum, sort: "replies:desc")

    expect(checked_sort).to eq("Most replies")
  end

  it "falls back to recent activity for an unknown sort key", :aggregate_failures do
    get project_forum_path(project, forum, sort: "author_id:desc")

    expect(response).to have_http_status(:ok)
    expect(checked_sort).to eq("Recent activity")
  end

  it "lists each topic's last reply without looking up its forum per topic" do
    # Counts cached lookups too: those repeat per row even when the database is spared.
    add_topics_with_a_reply = ->(count) { create_list(:message, count, forum:).each { create(:message, forum:, parent: it) } }
    add_topics_with_a_reply.(2)
    get project_forum_path(project, forum)
    baseline = count_queries { get project_forum_path(project, forum) }

    add_topics_with_a_reply.(3)

    expect(count_queries { get project_forum_path(project, forum) }).to be <= baseline
  end

  def count_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end
end
