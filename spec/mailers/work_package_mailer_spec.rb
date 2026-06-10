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
require_relative "shared_examples"

RSpec.describe WorkPackageMailer do
  include OpenProject::ObjectLinking
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers

  let(:work_package) do
    build_stubbed(:work_package,
                  type: build_stubbed(:type_standard),
                  project:,
                  assigned_to: assignee)
  end
  let(:project) { build_stubbed(:project) }
  let(:author) { build_stubbed(:user) }
  let(:recipient) { build_stubbed(:user) }
  let(:assignee) { build_stubbed(:user) }
  let(:journal) do
    build_stubbed(:work_package_journal,
                  journable: work_package,
                  user: author)
  end

  describe "#mentioned" do
    subject(:mail) { described_class.mentioned(recipient, journal) }

    context "with classic mode", with_settings: { work_packages_identifier: "classic" } do
      it "has a subject with # prefixed numeric id" do
        expect(mail.subject)
          .to eql I18n.t(:"mail.mention.subject",
                         user_name: author.name,
                         id: "##{work_package.id}",
                         subject: work_package.subject)
      end
    end

    context "with semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:work_package) do
        build_stubbed(:work_package,
                      type: build_stubbed(:type_standard),
                      project:,
                      assigned_to: assignee,
                      identifier: "PROJ-42",
                      sequence_number: 42)
      end

      it "has a subject with semantic identifier and no # prefix" do
        expect(mail.subject)
          .to eql I18n.t(:"mail.mention.subject",
                         user_name: author.name,
                         id: "PROJ-42",
                         subject: work_package.subject)
      end
    end

    it "is sent to the recipient" do
      expect(mail.to)
        .to contain_exactly(recipient.mail)
    end

    it "has a project header" do
      expect(mail["X-OpenProject-Project"].value)
        .to eql project.identifier
    end

    it "has a work package id header" do
      expect(mail["X-OpenProject-WorkPackage-Id"].value)
        .to eql work_package.id.to_s
    end

    it "has a work package author header" do
      expect(mail["X-OpenProject-WorkPackage-Author"].value)
        .to eql work_package.author.login
    end

    it "has a type header" do
      expect(mail["X-OpenProject-Type"].value)
        .to eql "WorkPackage"
    end

    it "has a message id header" do
      Timecop.freeze(Time.current) do
        expect(mail.message_id)
          .to eql "op.journal-#{journal.id}.#{Time.current.strftime('%Y%m%d%H%M%S')}.#{recipient.id}@example.net"
      end
    end

    it "has a references header" do
      journal_part = "op.journal-#{journal.id}@example.net"
      work_package_part = "op.work_package-#{work_package.id}@example.net"

      expect(mail.references)
        .to eql [work_package_part, journal_part]
    end

    it "has a work package assignee header" do
      expect(mail["X-OpenProject-WorkPackage-Assignee"].value)
        .to eql work_package.assigned_to.login
    end

    describe "rendering a journal note containing a WP reference" do
      shared_let(:persisted_project) { create(:project, identifier: "demo") }
      shared_let(:persisted_recipient) { create(:admin) }
      shared_let(:referenced_wp) { create(:work_package, project: persisted_project, subject: "child") }
      shared_let(:parent_wp) { create(:work_package, project: persisted_project, subject: "parent") }

      let(:persisted_journal) do
        create(:work_package_journal,
               journable: parent_wp,
               user: persisted_recipient,
               version: parent_wp.journals.maximum(:version).to_i + 1,
               notes: "see ##{referenced_wp.id}")
      end
      let(:mail) { described_class.mentioned(persisted_recipient, persisted_journal) }

      context "with classic mode",
              with_settings: { work_packages_identifier: "classic" } do
        it "renders the hash-prefixed numeric id in the text body" do
          expect(mail.text_part.body.to_s).to include("##{referenced_wp.id}")
        end

        it "links to the work package by its numeric id" do
          expect(mail.html_part.body.to_s)
            .to include("/notifications/details/#{parent_wp.id}/activity")
        end
      end

      context "with semantic mode",
              with_settings: { work_packages_identifier: "semantic" } do
        before do
          referenced_wp.update_columns(identifier: "DEMO-1", sequence_number: 1)
          parent_wp.update_columns(identifier: "DEMO-2", sequence_number: 2)
        end

        it "renders the bare semantic identifier in the text body" do
          body = mail.text_part.body.to_s
          expect(body).to include("DEMO-1")
          expect(body).not_to match(/##{referenced_wp.id}\b/)
        end

        it "links to the work package by its semantic identifier, not the numeric id" do
          body = mail.html_part.body.to_s
          expect(body).to include("/notifications/details/DEMO-2/activity")
          expect(body).not_to include("/notifications/details/#{parent_wp.id}/activity")
        end
      end
    end
  end

  describe "#watcher_changed" do
    subject(:deliveries) { ActionMailer::Base.deliveries }

    let(:watcher_changer) { author }

    context "for an added watcher" do
      subject(:mail) { described_class.watcher_changed(work_package, recipient, author, "added") }

      it "contains the WP subject in the mail subject" do
        expect(mail.subject)
          .to include(work_package.subject)
      end

      context "with classic mode", with_settings: { work_packages_identifier: "classic" } do
        it "includes the # prefixed numeric id in the subject" do
          expect(mail.subject).to include("##{work_package.id}")
        end
      end

      context "with semantic mode",
              with_settings: { work_packages_identifier: "semantic" } do
        let(:work_package) do
          build_stubbed(:work_package,
                        type: build_stubbed(:type_standard),
                        project:,
                        assigned_to: assignee,
                        identifier: "PROJ-42",
                        sequence_number: 42)
        end

        it "includes the semantic identifier without # prefix in the subject" do
          expect(mail.subject).to include("PROJ-42")
          expect(mail.subject).not_to match(/#PROJ-42/)
        end
      end

      it "has a references header" do
        expect(mail.references)
          .to eql "op.work_package-#{work_package.id}@example.net"
      end
    end

    context "for a removed watcher" do
      subject(:mail) { described_class.watcher_changed(work_package, recipient, author, "removed") }

      it "contains the WP subject in the mail subject" do
        expect(mail.subject)
          .to include(work_package.subject)
      end

      context "with classic mode", with_settings: { work_packages_identifier: "classic" } do
        it "includes the # prefixed numeric id in the subject" do
          expect(mail.subject).to include("##{work_package.id}")
        end
      end

      context "with semantic mode",
              with_settings: { work_packages_identifier: "semantic" } do
        let(:work_package) do
          build_stubbed(:work_package,
                        type: build_stubbed(:type_standard),
                        project:,
                        assigned_to: assignee,
                        identifier: "PROJ-42",
                        sequence_number: 42)
        end

        it "includes the semantic identifier without # prefix in the subject" do
          expect(mail.subject).to include("PROJ-42")
          expect(mail.subject).not_to match(/#PROJ-42/)
        end
      end

      it "has a references header" do
        expect(mail.references)
          .to eql "op.work_package-#{work_package.id}@example.net"
      end
    end

    describe "rendering the latest comment containing a WP reference" do
      shared_let(:persisted_project) { create(:project, identifier: "demo") }
      shared_let(:persisted_recipient) { create(:admin) }
      shared_let(:referenced_wp) { create(:work_package, project: persisted_project, subject: "child") }
      shared_let(:parent_wp) { create(:work_package, project: persisted_project, subject: "parent") }

      let(:mail) do
        create(:work_package_journal,
               journable: parent_wp,
               user: persisted_recipient,
               version: parent_wp.journals.maximum(:version).to_i + 1,
               notes: "Updated automatically by changing values within child work package ##{referenced_wp.id}")
        described_class.watcher_changed(parent_wp, persisted_recipient, persisted_recipient, "added")
      end

      context "with classic mode",
              with_settings: { work_packages_identifier: "classic" } do
        it "renders the hash-prefixed numeric id in the text body" do
          expect(mail.text_part.body.to_s).to include("##{referenced_wp.id}")
        end
      end

      context "with semantic mode",
              with_settings: { work_packages_identifier: "semantic" } do
        before do
          referenced_wp.update_columns(identifier: "DEMO-1", sequence_number: 1)
        end

        it "renders the bare semantic identifier in the text body" do
          body = mail.text_part.body.to_s
          expect(body).to include("DEMO-1")
          expect(body).not_to match(/##{referenced_wp.id}\b/)
        end

        it "renders the bare semantic identifier in the html body" do
          body = mail.html_part.body.to_s
          expect(body).to include("DEMO-1")
        end
      end
    end

    describe "rendering a cross-project WP reference to a recipient without visibility",
             with_settings: { work_packages_identifier: "semantic" } do
      shared_let(:parent_project) { create(:project, identifier: "parent-proj") }
      shared_let(:child_project) { create(:project, identifier: "child-proj") }
      shared_let(:parent_wp) { create(:work_package, project: parent_project, subject: "parent") }
      shared_let(:child_wp) { create(:work_package, project: child_project, subject: "child") }
      shared_let(:reader_role) { create(:project_role, permissions: %i[view_work_packages]) }
      shared_let(:reader) { create(:user, member_with_roles: { parent_project => reader_role }) }

      let(:mail) do
        child_wp.update_columns(identifier: "CHILDPROJ-1", sequence_number: 1)
        create(:work_package_journal,
               journable: parent_wp,
               user: reader,
               version: parent_wp.journals.maximum(:version).to_i + 1,
               notes: "Updated automatically by changing values within child work package ##{child_wp.id}")
        described_class.watcher_changed(parent_wp, reader, reader, "added")
      end

      it "renders the semantic identifier as plain text in the text body" do
        body = mail.text_part.body.to_s
        expect(body).to include("CHILDPROJ-1")
        expect(body).not_to match(/##{child_wp.id}\b/)
      end

      it "renders the semantic identifier without an anchor in the html body" do
        body = mail.html_part.body.to_s
        expect(body).to include("CHILDPROJ-1")
        expect(body).not_to include(%(href="/work_packages/#{child_wp.id}"))
        expect(body).not_to include(%(href="/work_packages/CHILDPROJ-1"))
      end
    end

    describe "rendering a quickinfo/detailed macro in the latest comment" do
      shared_let(:persisted_project) { create(:project, identifier: "demo") }
      shared_let(:persisted_recipient) { create(:admin) }
      shared_let(:macro_type) { create(:type, name: "Task") }
      shared_let(:macro_status) { create(:status, name: "New") }
      shared_let(:referenced_wp) do
        create(:work_package,
               project: persisted_project,
               type: macro_type,
               status: macro_status,
               subject: "Cats V Dogs")
      end
      shared_let(:parent_wp) { create(:work_package, project: persisted_project, subject: "parent") }

      let(:mail) do
        create(:work_package_journal,
               journable: parent_wp,
               user: persisted_recipient,
               version: parent_wp.journals.maximum(:version).to_i + 1,
               notes: "ref ##{referenced_wp.id} ##{'#'}#{referenced_wp.id} ###{'#'}#{referenced_wp.id}")
        described_class.watcher_changed(parent_wp, persisted_recipient, persisted_recipient, "added")
      end

      context "with semantic mode",
              with_settings: { work_packages_identifier: "semantic" } do
        before { referenced_wp.update_columns(identifier: "DEMO-1", sequence_number: 1) }

        it "renders ## quickinfo as a static anchor with type + id + subject" do
          body = mail.html_part.body.to_s
          expect(body).to match(%r{<a\b[^>]*>Task DEMO-1: Cats V Dogs</a>})
        end

        it "renders ### detailed as a static anchor with status + type + id + subject" do
          body = mail.html_part.body.to_s
          expect(body).to match(%r{<a\b[^>]*>New Task DEMO-1: Cats V Dogs</a>})
        end

        it "never leaks <opce-macro-wp-quickinfo> into the html body" do
          expect(mail.html_part.body.to_s).not_to include("opce-macro-wp-quickinfo")
        end
      end

      context "with classic mode",
              with_settings: { work_packages_identifier: "classic" } do
        it "renders ## quickinfo as a static anchor with type + #N + subject" do
          body = mail.html_part.body.to_s
          expect(body).to match(%r{<a\b[^>]*>Task ##{referenced_wp.id}: Cats V Dogs</a>})
        end

        it "renders ### detailed as a static anchor with status + type + #N + subject" do
          body = mail.html_part.body.to_s
          expect(body).to match(%r{<a\b[^>]*>New Task ##{referenced_wp.id}: Cats V Dogs</a>})
        end
      end
    end
  end
end
