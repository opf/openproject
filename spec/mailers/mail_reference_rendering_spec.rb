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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Mail rendering of work package references", # rubocop:disable RSpec/DescribeClass
               with_settings: { work_packages_identifier: "classic" } do
  shared_let(:view_role) { create(:project_role, permissions: %i[view_work_packages]) }
  shared_let(:shared_project) { create(:project, public: false, enabled_module_names: %w[news forums documents]) }
  shared_let(:private_project) { create(:project, public: false) }
  shared_let(:author) do
    create(:user, member_with_roles: { shared_project => view_role, private_project => view_role })
  end
  shared_let(:recipient) { create(:user, member_with_roles: { shared_project => view_role }) }
  shared_let(:visible_recipient) do
    create(:user, member_with_roles: { shared_project => view_role, private_project => view_role })
  end
  shared_let(:referenced_type) { create(:type, name: "OrchidType") }
  shared_let(:referenced_status) { create(:status, name: "OrchidStatus") }
  shared_let(:referenced_work_package) do
    create(:work_package,
           project: private_project,
           type: referenced_type,
           status: referenced_status,
           subject: "Orchid bridge subject")
  end

  let(:text) { "please review #{'###'}#{referenced_work_package.id}" }

  before { User.current = author }

  shared_examples "renders references as the recipient" do
    it "keeps a bare reference and omits subject, type, and status the recipient cannot view" do
      body = mail_for(recipient).html_part.body.to_s

      expect(body).to include("##{referenced_work_package.id}")
      expect(body).not_to include(referenced_work_package.subject)
      expect(body).not_to include(referenced_type.name)
      expect(body).not_to include(referenced_status.name)
    end

    it "expands subject, type, and status when the recipient can view the referenced work package" do
      body = mail_for(visible_recipient).html_part.body.to_s

      expect(body).to include(referenced_work_package.subject)
      expect(body).to include(referenced_type.name)
      expect(body).to include(referenced_status.name)
    end
  end

  describe "UserMailer#news_added" do
    let(:news) { create(:news, project: shared_project, author:, description: text) }

    def mail_for(user) = UserMailer.news_added(user, news)

    it_behaves_like "renders references as the recipient"
  end

  describe "UserMailer#news_comment_added" do
    let(:news) { create(:news, project: shared_project, author:) }
    let(:comment) { create(:comment, commented: news, author:, comments: text) }

    def mail_for(user) = UserMailer.news_comment_added(user, comment)

    it_behaves_like "renders references as the recipient"
  end

  describe "UserMailer#message_posted" do
    let(:forum) { create(:forum, project: shared_project) }
    let(:message) { create(:message, forum:, author:, content: text) }

    def mail_for(user) = UserMailer.message_posted(user, message)

    it_behaves_like "renders references as the recipient"
  end

  describe "DocumentsMailer#document_added" do
    let(:document) { create(:document, project: shared_project, description: text) }

    def mail_for(user) = DocumentsMailer.document_added(user, document)

    it_behaves_like "renders references as the recipient"
  end

  describe "AnnouncementMailer#announce" do
    def mail_for(user) = AnnouncementMailer.announce(user, subject: "Announcement", body: text)

    it_behaves_like "renders references as the recipient"
  end

  describe "ProjectArtifactsMailer#creation_wizard_submitted" do
    let(:artifact_work_package) { create(:work_package, project: shared_project) }

    before do
      shared_project.update!(project_creation_wizard_notification_text: text)
    end

    def mail_for(user) = ProjectArtifactsMailer.creation_wizard_submitted(user, shared_project, artifact_work_package)

    it_behaves_like "renders references as the recipient"
  end

  describe "ProjectMailer#project_created" do
    before do
      allow(Setting).to receive(:new_project_notification_text).and_return(text)
    end

    def mail_for(user) = ProjectMailer.project_created(shared_project, user:)

    it_behaves_like "renders references as the recipient"
  end

  describe "mail layout header" do
    before do
      allow(Setting).to receive(:localized_emails_header).and_return(text)
    end

    def mail_for(user) = UserMailer.test_mail(user)

    it_behaves_like "renders references as the recipient"
  end
end
