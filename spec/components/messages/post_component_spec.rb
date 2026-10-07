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

RSpec.describe Messages::PostComponent, type: :component do
  subject(:rendered_component) do
    render_inline(described_class.new(message:, topic:))
  end

  shared_let(:project) { create(:project) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:author) { create(:user, firstname: "Alice", lastname: "Author") }
  shared_let(:topic) { create(:message, forum:, author:, subject: "Release planning", content: "Opening post") }

  let(:message) { topic }
  let(:permissions) { %i[view_messages add_messages] }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  it "anchors the card on the message id" do
    expect(rendered_component).to have_css("#message-#{topic.id}", text: "Opening post")
  end

  it "signs the opening post at the bottom rather than heading it", :aggregate_failures do
    expect(rendered_component).to have_no_test_selector("message-header")
    expect(rendered_component).to have_test_selector("message-signature", text: "Alice Author")
    expect(rendered_component)
      .to have_css("[data-test-selector='message-signature'] [data-test-selector='message-actions-#{topic.id}']")
  end

  it "starts the thread without a stem above it" do
    expect(rendered_component).to have_no_css(".op-forum-post-stem")
  end

  it "offers copying a link and quoting the opening post", :aggregate_failures do
    expect(rendered_component).to have_test_selector("message-actions-#{topic.id}")
    expect(rendered_component).to have_css("clipboard-copy", text: "Copy link to clipboard", visible: :all)
    expect(rendered_component).to have_link("Quote", visible: :all)
  end

  context "with permission to edit and delete messages on the opening post" do
    let(:permissions) { %i[view_messages add_messages edit_messages delete_messages] }

    it "offers editing it but leaves deleting the topic to the page header", :aggregate_failures do
      expect(rendered_component).to have_link("Edit", visible: :all)
      expect(rendered_component).to have_no_button("Delete", visible: :all)
    end
  end

  context "for a reply" do
    let(:message) { create(:message, forum:, parent: topic, author:, subject: "RE: Release planning") }

    it "heads the reply with its author", :aggregate_failures do
      expect(rendered_component).to have_test_selector("message-header", text: "Alice Author")
      expect(rendered_component).to have_no_test_selector("message-signature")
    end

    it "hangs from the thread's stem" do
      expect(rendered_component).to have_css(".op-forum-post-stem + #message-#{message.id}")
    end

    it "leaves out its subject, which only repeats the topic's" do
      expect(rendered_component).to have_no_text("RE: Release planning")
    end

    it "links its timestamp to its anchor" do
      expect(rendered_component).to have_link(href: /#message-#{message.id}\z/)
    end

    it "offers copying a link and quoting", :aggregate_failures do
      expect(rendered_component).to have_test_selector("message-actions-#{message.id}")
      expect(rendered_component).to have_css("clipboard-copy", text: "Copy link to clipboard", visible: :all)
      expect(rendered_component).to have_link("Quote", visible: :all)
    end

    it "hides edit and delete from users who may not change it", :aggregate_failures do
      expect(rendered_component).to have_no_link("Edit", visible: :all)
      expect(rendered_component).to have_no_button("Delete", visible: :all)
    end

    context "with permission to edit and delete messages" do
      let(:permissions) { %i[view_messages add_messages edit_messages delete_messages] }

      it "offers edit and delete", :aggregate_failures do
        expect(rendered_component).to have_link("Edit", visible: :all)
        expect(rendered_component).to have_button("Delete", visible: :all)
      end
    end

    context "when the topic is locked" do
      before do
        message
        topic.update_column(:locked, true)
      end

      it "offers no quote" do
        expect(rendered_component).to have_no_link("Quote", visible: :all)
      end
    end
  end

  context "when the author is gone" do
    before { topic.update_column(:author_id, nil) }

    it "renders without an author" do
      expect(rendered_component).to have_css("#message-#{topic.id}", text: "Opening post")
    end
  end
end
