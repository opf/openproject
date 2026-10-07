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

RSpec.describe "Topic form", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:forum) { create(:forum, project:, name: "General") }
  shared_let(:other_forum) { create(:forum, project:, name: "Support") }
  shared_let(:author) { create(:user, member_with_permissions: { project => %i[view_messages add_messages edit_own_messages] }) }
  shared_let(:moderator) do
    create(:user, member_with_permissions: { project => %i[view_messages add_messages edit_messages] })
  end
  shared_let(:topic) { create(:message, forum:, author:, subject: "Release planning") }

  let(:html) { Capybara.string(response.body) }

  context "as an author" do
    current_user { author }

    it "offers no moderation fields on a new topic", :aggregate_failures do
      get new_project_forum_topic_path(project, forum)

      expect(html).to have_field("Subject")
      expect(html).to have_no_field("Sticky")
      expect(html).to have_no_field("Locked")
    end

    it "shows errors no field displays above the form", :aggregate_failures do
      someone_elses_file = create(:attachment, container: nil, author: moderator)

      post project_forum_topics_path(project, forum),
           params: { message: { subject: "With a file", content: "Body" }, attachments: { "0" => { id: someone_elses_file.id } } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(html).to have_test_selector("message-form-errors", text: "Attachments does not exist")
    end

    it "re-renders the form with the field error for blank content", :aggregate_failures do
      post project_forum_topics_path(project, forum), params: { message: { subject: "Kept subject", content: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(html).to have_field("Subject", with: "Kept subject")
      expect(html).to have_text("Content can't be blank")
      expect(html).to have_no_test_selector("message-form-errors")
    end
  end

  context "as a moderator" do
    current_user { moderator }

    it "offers sticky and locked on a new topic", :aggregate_failures do
      get new_project_forum_topic_path(project, forum)

      expect(html).to have_field("Sticky", type: :checkbox)
      expect(html).to have_field("Locked", type: :checkbox)
      expect(html).to have_no_select("Forum")
    end

    it "offers moving an existing topic to another forum" do
      get edit_project_forum_topic_path(project, forum, topic)

      expect(html).to have_select("Forum", options: %w[General Support], selected: "General")
    end

    it "updates the topic", :aggregate_failures do
      put project_forum_topic_path(project, forum, topic),
          params: { message: { subject: "Renamed", content: "Body", sticky: "1" } }

      expect(response).to redirect_to(project_forum_topic_path(project, forum, topic))
      expect(topic.reload).to have_attributes(subject: "Renamed", sticky?: true)
    end
  end

  describe "replying" do
    current_user { author }

    it "offers only the message content, hanging from the thread's stem", :aggregate_failures do
      get project_forum_topic_path(project, forum, topic)

      expect(html).to have_no_css("h2", text: "Reply")
      expect(html).to have_no_field("Subject")
      expect(html).to have_css("#reply > .op-forum-post-stem:first-child + .op-forum-reply--box > form")
    end

    it "uses the compact editor of the work package activity, keeping its revisions per topic", :aggregate_failures do
      get project_forum_topic_path(project, forum, topic)

      editor = html.find("#reply opce-ckeditor-augmented-textarea", visible: :all)
      expect(editor[:class]).to include("ck-editor-primer-adjusted")
      expect(editor["data-editor-type"]).to eq('"constrained"')
      expect(editor["data-storage-key"]).to eq(%("forum-topic-#{topic.id}-reply-new"))
    end

    it "keeps the full editor for topics" do
      get new_project_forum_topic_path(project, forum)

      expect(html.find("opce-ckeditor-augmented-textarea", visible: :all)["data-editor-type"]).to be_nil
    end

    it "titles the reply after its topic" do
      post reply_to_project_forum_topic_path(project, forum, topic), params: { reply: { content: "Agreed" } }

      expect(topic.children.last).to have_attributes(subject: "RE: Release planning", content: "Agreed")
    end

    it "lands on the new reply" do
      post reply_to_project_forum_topic_path(project, forum, topic), params: { reply: { content: "Agreed" } }

      reply = topic.children.last
      expect(response).to redirect_to("#{project_forum_topic_path(project, forum, topic)}?r=#{reply.id}#message-#{reply.id}")
    end

    it "brings the reply box back into view after posting it" do
      get project_forum_topic_path(project, forum, topic)

      expect(html.find("#reply form")[:action]).to eq("#{reply_to_project_forum_topic_path(project, forum, topic)}#reply")
    end

    it "re-renders the thread with the field error for a blank reply", :aggregate_failures do
      post reply_to_project_forum_topic_path(project, forum, topic), params: { reply: { content: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(topic.children).to be_empty
      expect(html).to have_test_selector("forum-post-#{topic.id}")
      expect(html).to have_css("#reply", text: "Content can't be blank")
      expect(html).to have_no_test_selector("message-form-errors")
    end

    it "shows errors no field displays above the reply box", :aggregate_failures do
      someone_elses_file = create(:attachment, container: nil, author: moderator)

      post reply_to_project_forum_topic_path(project, forum, topic),
           params: { reply: { content: "Agreed" }, attachments: { "0" => { id: someone_elses_file.id } } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(html).to have_css("#reply #{test_selector('message-form-errors')}", text: "Attachments does not exist")
    end

    it "ignores a subject posted with a reply" do
      post reply_to_project_forum_topic_path(project, forum, topic), params: { reply: { subject: "Hijacked", content: "Agreed" } }

      expect(topic.children.last.subject).to eq("RE: Release planning")
    end

    it "fits the reply title within the subject length of a long topic subject" do
      topic.update_column(:subject, "x" * 255)

      post reply_to_project_forum_topic_path(project, forum, topic), params: { reply: { content: "Agreed" } }

      expect(topic.children.last.subject).to start_with("RE: xxx").and(have_attributes(length: 255))
    end

    it "cancels editing a reply back to that reply in its thread" do
      reply = create(:message, forum:, parent: topic, author:, subject: "RE: Release planning")

      get edit_project_forum_topic_path(project, forum, reply)

      expect(html).to have_link("Cancel",
                                href: "#{project_forum_topic_path(project, forum, topic)}?r=#{reply.id}#message-#{reply.id}")
    end

    it "offers no subject when editing a reply" do
      reply = create(:message, forum:, parent: topic, author:, subject: "RE: Release planning")

      get edit_project_forum_topic_path(project, forum, reply)

      expect(html).to have_no_field("Subject")
    end
  end
end
