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

RSpec.describe "Loading hidden forum replies", type: :rails_request do
  shared_let(:forum) { create(:forum) }
  shared_let(:reader) { create(:user, member_with_permissions: { forum.project => %i[view_messages] }) }
  shared_let(:topic) { create(:message, forum:) }
  shared_let(:replies) do
    Array.new(45) { |i| create(:message, forum:, parent: topic, created_at: topic.created_at + (i + 1).minutes) }
  end

  current_user { reader }

  let(:stream) { Capybara.string(response.body[%r{<template>(.*)</template>}m, 1].to_s) }

  def load_replies(after: topic.id, before: replies[25].id)
    get replies_project_forum_topic_path(forum.project, forum, topic, after:, before:), as: :turbo_stream
  end

  it "replaces the gap with the page before its lower bound and a smaller gap above it", :aggregate_failures do
    load_replies

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(action="replace" target="forum-thread-gap-#{topic.id}-#{replies[25].id}"))
    expect(stream).to have_css("[data-test-selector^='forum-post-']", count: 20)
    expect(stream).to have_css("#message-#{replies[5].id}")
    expect(stream).to have_no_css("#message-#{replies[4].id}")
    expect(stream).to have_test_selector("forum-thread-gap", text: "Load previous 5 replies")
    expect(stream).to have_css("#{test_selector('forum-thread-gap')} a[autofocus]")
  end

  it "closes a gap of a page or less, focusing its first reply", :aggregate_failures do
    load_replies(before: replies[10].id)

    expect(stream).to have_no_test_selector("forum-thread-gap")
    expect(stream).to have_css("#message-#{replies[0].id}[autofocus]")
  end

  context "for a user who cannot read the topic" do
    current_user { create(:user) }

    it "forbids users who cannot read the topic" do
      load_replies

      expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
    end
  end
end
