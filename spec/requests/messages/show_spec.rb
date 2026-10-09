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

  context "with a long thread" do
    shared_let(:long_topic) { create(:message, forum:, subject: "Long") }
    shared_let(:long_replies) do
      Array.new(65) { |i| create(:message, forum:, parent: long_topic, created_at: long_topic.created_at + (i + 1).minutes) }
    end

    it "shows the opening post, a gap and the latest page", :aggregate_failures do
      get project_forum_topic_path(forum.project, forum, long_topic)

      expect(html).to have_css("[data-test-selector^='forum-post-']", count: 21)
      expect(html).to have_test_selector("forum-thread-gap", count: 1, text: "Load previous 20 replies (out of 45)")
      expect(html).to have_css("#message-#{long_replies.last.id}")
    end

    it "shows a hidden reply a link points to, between two gaps", :aggregate_failures do
      # Reply 26 sits on the second page (replies 21–40), clear of both the first page and the latest one (46–65).
      get project_forum_topic_path(forum.project, forum, long_topic, r: long_replies[25].id)

      expect(html).to have_css("#message-#{long_replies[25].id}")
      expect(html).to have_test_selector("forum-thread-gap", count: 2)
    end
  end

  context "with work packages created from its messages" do
    current_user { create(:user, member_with_permissions: { forum.project => %i[view_messages view_work_packages] }) }

    def create_work_package_from(message, subject: "Created")
      create(:work_package, project: forum.project, subject:).tap { MessageWorkPackage.create!(message:, work_package: it) }
    end

    it "hangs each one on the lifeline after the message it came from" do
      work_package = create_work_package_from(replies.first, subject: "Freeze on Friday")

      get project_forum_topic_path(forum.project, forum, topic)

      branch = test_selector("message-created-work-package-#{work_package.id}")

      expect(html).to have_css("#message-#{replies.first.id} ~ #{branch}", text: "Freeze on Friday")
    end

    it "names them in the topic header, including those from replies hidden behind a gap" do
      long_topic = create(:message, forum:)
      long_replies = Array.new(25) do |i|
        create(:message, forum:, parent: long_topic, created_at: long_topic.created_at + (i + 1).minutes)
      end
      work_package = create_work_package_from(long_replies.first)

      get project_forum_topic_path(forum.project, forum, long_topic)

      expect(html).to have_test_selector("topic-summary", text: work_package.formatted_id)
    end

    it "looks them up without a query per message or per work package" do
      create_work_package_from(replies.first)
      get project_forum_topic_path(forum.project, forum, topic)
      baseline = count_queries { get project_forum_topic_path(forum.project, forum, topic) }

      replies.drop(1).each { create_work_package_from(it) }
      create_work_package_from(topic)

      expect(count_queries { get project_forum_topic_path(forum.project, forum, topic) }).to be <= baseline
    end
  end

  def count_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end
end
