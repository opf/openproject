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

RSpec.describe MessagesController, with_settings: { journal_aggregation_time_minutes: 0 } do
  let(:user) { create(:user) }
  let(:permissions) { [] }
  let(:project) { create(:project, member_with_permissions: { user => permissions }) }
  let!(:forum) { create(:forum, project:) }

  let(:filename) { "testfile.txt" }
  let(:file) { Rails.root.join("spec/fixtures/files", filename).open }

  before do
    login_as(user)
  end

  describe "#show" do
    context "when the user is allowed to view messages" do
      let(:permissions) { %i[view_messages] }
      let!(:message) { create(:message, forum:) }

      it "renders the show template" do
        get :show, params: { project_id: project.id, forum_id: forum.id, id: message.id }

        expect(response).to render_template "messages/show"
        expect(assigns(:topic)).to be_present
        expect(assigns(:forum)).to be_present
        expect(assigns(:project)).to be_present
      end
    end
  end

  describe "#update" do
    let(:message) { create(:message, forum:) }
    let(:other_forum) { create(:forum, project:) }
    let(:permissions) { %i[edit_messages] }

    context "when moving it to another forum" do
      before do
        put :update, params: { project_id: project.id,
                               forum_id: forum.id,
                               id: message,
                               message: { forum_id: other_forum } }
      end

      it "allows for changing the board" do
        expect(message.reload.forum).to eq(other_forum)
      end
    end

    context "when uploading an attachment" do
      let!(:message) { create(:message, forum: forum) }
      let(:uncontainered) { create(:attachment, container: nil, author: user) }
      let(:attachment_id) { "attachments_#{uncontainered.id}" }

      let(:params) do
        {
          project_id: project.id,
          forum_id: forum.id,
          id: message.id,
          attachments: { "1" => { id: uncontainered.id } }
        }
      end

      describe "when adding an attachment" do
        let(:permissions) { %i[edit_messages] }

        context "with journaling" do
          before do
            put(:update, params:)

            message.reload
          end

          it "stores attachment details in the journal entry" do
            expect(message.journals.last.details).to have_key attachment_id
            expect(message.journals.last.details[attachment_id].last).to eq(uncontainered.filename)
          end
        end
      end
    end
  end

  describe "quote" do
    let(:message) { create(:message, content: "foo", subject: "subject", forum:) }

    context "when allowed" do
      let(:user) { create(:admin) }

      it "renders the content as json" do
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :json

        expect(response).to be_successful
        expect(response.body).to eq '{"subject":"RE: subject","content":" wrote:\n\u003e foo\n\n"}'
      end

      it "escapes HTML in quoted message author" do
        user.firstname = "Hello"
        user.lastname = "<b>world</b>"
        user.save! validate: false

        message.update!(author: user)
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :json

        expect(response).to be_successful
        expect(response.parsed_body["content"]).to eq "Hello &lt;b&gt;world&lt;/b&gt; wrote:\n> foo\n\n"
      end

      it "prefixes each line with > for multiline content" do
        message.update!(content: "line one\nline two\nline three")
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :json

        body = response.parsed_body
        expect(body["content"]).to include("> line one\n> line two\n> line three")
      end

      it "replaces <pre> blocks with [...]" do
        message.update!(content: "before\n<pre>some code\nblock</pre>\nafter")
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :json

        body = response.parsed_body
        expect(body["content"]).to include("[...]")
        expect(body["content"]).not_to include("<pre>")
        expect(body["content"]).not_to include("some code")
      end

      it "preserves double quotes in content" do
        message.update!(content: 'she said "hello" to him')
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :json

        expect(response).to be_successful
        expect(response.parsed_body["content"]).to include('she said "hello" to him')
      end

      it "does not add RE: prefix when subject already starts with RE:" do
        message.update!(subject: "RE: already replied")
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :json

        expect(response.parsed_body["subject"]).to eq "RE: already replied"
      end

      it "adds RE: prefix to subject" do
        message.update!(subject: "original topic")
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :json

        expect(response.parsed_body["subject"]).to eq "RE: original topic"
      end

      it "handles nil content gracefully" do
        message.update_columns(content: nil)
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :json

        expect(response).to be_successful
        expect(response.parsed_body["content"]).to include("> \n\n")
      end

      it "returns not acceptable for non-JSON requests" do
        get :quote, params: { project_id: project.id, forum_id: forum.id, id: message.id }, format: :html

        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end
end
