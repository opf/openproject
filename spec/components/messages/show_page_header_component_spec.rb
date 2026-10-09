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

require "rails_helper"

RSpec.describe Messages::ShowPageHeaderComponent, type: :component do
  subject(:rendered_component) do
    render_inline(described_class.new(topic:))
  end

  shared_let(:forum) { create(:forum) }
  shared_let(:topic) { create(:message, forum:, subject: "Release planning") }

  current_user { create(:user, member_with_permissions: { forum.project => %i[view_messages] }) }

  it "tells when the topic started" do
    expect(rendered_component).to have_test_selector("topic-summary", text: "Started")
    expect(find_test_selector("topic-summary")).to have_css("relative-time[datetime='#{topic.created_at.iso8601}']")
  end

  context "with replies from the topic's author and someone else" do
    let(:author) { create(:user) }

    before do
      topic.update_column(:author_id, author.id)
      create(:message, forum:, parent: topic, author:)
      create(:message, forum:, parent: topic, author: create(:user))
    end

    it "counts the replies and the participants" do
      expect(rendered_component).to have_test_selector("topic-summary", text: /2 replies · 2 participants\z/)
    end
  end

  it "counts no participants for a topic whose author is gone and nobody replied to" do
    expect(rendered_component).to have_no_text("participant")
  end

  it "states that nobody replied yet" do
    expect(rendered_component).to have_test_selector("topic-summary", text: "No replies yet")
  end

  context "with one reply" do
    before { topic.update_column(:replies_count, 1) }

    it "counts it in the description" do
      expect(rendered_component).to have_test_selector("topic-summary", text: "1 reply")
    end
  end

  context "with several replies" do
    before { topic.update_column(:replies_count, 3) }

    it "counts them in the description" do
      expect(rendered_component).to have_test_selector("topic-summary", text: "3 replies")
    end
  end

  context "with permission to reply, edit and delete messages" do
    current_user do
      create(:user, member_with_permissions: { forum.project => %i[view_messages add_messages edit_messages delete_messages] })
    end

    it "leaves quoting and editing to the opening post's menu but keeps deleting the topic", :aggregate_failures do
      expect(rendered_component).to have_no_link("Quote")
      expect(rendered_component).to have_no_link("Edit")
      expect(rendered_component).to have_link("Delete")
    end
  end

  context "for a user who may only delete their own messages" do
    current_user { create(:user, member_with_permissions: { forum.project => %i[view_messages delete_own_messages] }) }

    it "offers no deleting someone else's topic" do
      expect(rendered_component).to have_no_link("Delete")
    end
  end
end
