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
  let(:project) { create(:project) }
  let(:role) { create(:project_role) }
  let!(:member) do
    create(:member,
           project:,
           principal: user,
           roles: [role])
  end
  let!(:forum) do
    create(:forum,
           project:)
  end

  let(:filename) { "testfile.txt" }
  let(:file) { File.open(Rails.root.join("spec/fixtures/files", filename)) }

  before { allow(User).to receive(:current).and_return user }

  describe "#show" do
    context "with a public project" do
      let(:user) { User.anonymous }
      let(:project) { create(:public_project) }
      let!(:message) { create(:message, forum:) }

      context "when login_required", with_settings: { login_required: true } do
        it "redirects to login" do
          get :show, params: { project_id: project.id, id: message.id }
          expect(response).to redirect_to signin_path(back_url: topic_url(message.id))
        end
      end

      context "when not login_required", with_settings: { login_required: false } do
        it "renders the show template" do
          get :show, params: { project_id: project.id, id: message.id }

          expect(response).to be_successful
          expect(response).to render_template "messages/show"
          expect(assigns(:topic)).to be_present
          expect(assigns(:forum)).to be_present
          expect(assigns(:project)).to be_present
        end
      end
    end
  end

  describe "#update" do
    let(:message) { create(:message, forum:) }
    let(:other_forum) { create(:forum, project:) }

    before do
      role.add_permission!(:edit_messages) and user.reload
      put :update, params: { id: message,
                             message: { forum_id: other_forum } }
    end

    it "allows for changing the board" do
      expect(message.reload.forum).to eq(other_forum)
    end

    context "attachment upload" do
      let!(:message) { create(:message) }
      let(:attachment_id) { "attachments_#{message.attachments.first.id}" }
      # Attachment is already uploaded
      let(:attachment) { create(:attachment, container: nil, author: user) }
      let(:params) do
        { id: message.id,
          attachments: { "0" => { "id" => attachment.id } } }
      end

      describe "add" do
        before do
          allow_any_instance_of(Message).to receive(:editable_by?).and_return(true)
        end

        context "journal" do
          before do
            put(:update, params:)

            message.reload
          end

          describe "#key" do
            subject { message.journals.last.details }

            it { is_expected.to have_key attachment_id }
          end

          describe "#value" do
            subject { message.journals.last.details[attachment_id].last }

            it { is_expected.to eq(attachment.filename) }
          end
        end
      end
    end

    describe "#remove" do
      let!(:attachment) do
        create(:attachment,
               container: message,
               author: user,
               filename:)
      end
      let!(:attachable_journal) do
        create(:journal_attachable_journal,
               journal: message.journals.last,
               attachment:,
               filename:)
      end

      before do
        message.reload
        message.attachments.delete(attachment)
        message.reload
      end

      context "journal" do
        let(:attachment_id) { "attachments_#{attachment.id}" }

        describe "#key" do
          subject { message.journals.last.details }

          it { is_expected.to have_key attachment_id }
        end

        describe "#value" do
          subject { message.journals.last.details[attachment_id].first }

          it { is_expected.to eq(filename) }
        end
      end
    end
  end

  describe "quote" do
    let(:message) { create(:message, content: "foo", subject: "subject", forum:) }

    context "when allowed" do
      let(:user) { create(:admin) }

      before do
        login_as user
      end

      it "renders the content as json" do
        get :quote, params: { forum_id: forum.id, id: message.id }, format: :json

        expect(response).to be_successful
        expect(response.body).to eq '{"subject":"RE: subject","content":" wrote:\n\u003e foo\n\n"}'
      end

      it "escapes HTML in quoted message author" do
        user.firstname = "Hello"
        user.lastname = "<b>world</b>"
        user.save! validate: false

        message.update!(author: user)
        get :quote, params: { forum_id: forum.id, id: message.id }, format: :json

        expect(response).to be_successful
        expect(response.parsed_body["content"]).to eq "Hello &lt;b&gt;world&lt;/b&gt; wrote:\n> foo\n\n"
      end
    end
  end
end
