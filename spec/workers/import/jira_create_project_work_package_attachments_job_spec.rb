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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

# The import only produces valid data with semantic identifiers enabled: Jira project keys are
# uppercase, which Projects::Identifier rejects in classic mode.
RSpec.describe Import::JiraCreateProjectWorkPackageAttachmentsJob,
               :webmock,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with a jira demo issue"
  include_context "with ssrf stubs"

  let(:attachment_content) { Rails.root.join("spec/fixtures/files/airplane-wing-over-cloudy-sky.jpg").binread }
  let(:download_attachment_url) { "https://jira-dc.openproject.org/secure/attachment/10100/airplane-wing-over-cloudy-sky.jpg" }

  before do
    stub_request(:get, download_attachment_url)
      .to_return(status: 200, body: attachment_content, headers: { "Content-Type" => "image/jpg" })

    create_project_role
    create_project
    create_work_packages
  end

  describe "#perform" do
    it "creates an attachment on the work package" do
      create_work_package_attachments

      work_package = WorkPackage.find("DPPP-6")
      expect(work_package.attachments.count).to eq(1)
      expect(work_package.attachments.first.filename).to eq("airplane-wing-over-cloudy-sky.jpg")
    end

    it "takes the attachment timestamps from the date it was attached in Jira" do
      create_work_package_attachments

      attached_at = Time.zone.parse(jira_issue_payload["fields"]["attachment"].sole["created"])
      attachment = WorkPackage.find("DPPP-6").attachments.sole

      expect(attachment.created_at).to eq(attached_at)
      expect(attachment.updated_at).to eq(attached_at)
    end

    it "does not journalize the attachment, leaving the migration entry as the only addition" do
      expect { create_work_package_attachments }
        .to change { WorkPackage.find("DPPP-6").journals.count }.by(1)
    end

    it "records the attachment in every journal, so that none reports it as a later change" do
      create_work_package_attachments

      journals = WorkPackage.find("DPPP-6").journals.order(:version)
      attachment = Attachment.sole

      expect(journals.map { |journal| journal.attachable_journals.pluck(:attachment_id) })
        .to all(eq([attachment.id]))
      expect(journals.reject(&:initial?).flat_map { |journal| journal.details.keys })
        .not_to include("attachments_#{attachment.id}")
    end

    it "keeps the imported Jira changelog as the only record of when it was attached" do
      create_work_package_attachments

      changelog_entry = jira_issue_payload["changelog"]["histories"].find do |history|
        history["items"].any? { |item| item["field"] == "Attachment" }
      end
      journals = WorkPackage.find("DPPP-6").journals.order(:version).select do |journal|
        journal.cause_import_history.to_a.any? do |entry|
          entry["items"].to_a.any? { |item| item["field"] == "Attachment" }
        end
      end

      expect(journals.map(&:created_at)).to eq([Time.zone.parse(changelog_entry["created"])])
    end

    it "closes the activity with a migration entry" do
      create_work_package_attachments

      journal = WorkPackage.find("DPPP-6").journals.order(:version).last
      expect(journal.cause).to eq("type" => "import", "migrated" => true)
      expect(journal.created_at).to be_within(1.minute).of(Time.current)
    end

    it "keeps the Jira timestamps on the work package" do
      create_work_package_attachments

      work_package = WorkPackage.find("DPPP-6")
      expect(work_package.created_at).to eq(Time.zone.parse(jira_issue_payload["fields"]["created"]))
      expect(work_package.updated_at).to eq(Time.zone.parse(jira_issue_payload["fields"]["updated"]))
    end

    it "adds the attachment author as a project member" do
      create_work_package_attachments

      project = Project.find_by!(identifier: jira_project_key)
      expect(project.users).to include(op_user)
    end

    context "when the attachment download fails" do
      before do
        stub_request(:get, download_attachment_url).to_return(status: 404, body: "Not Found")
      end

      it "fails the job so that the import run reports the error" do
        expect { create_work_package_attachments }
          .to raise_error(Import::JiraClient::ApiError, "Jira API returned error status 404")
      end

      it "does not create an attachment" do
        expect { create_work_package_attachments }.to raise_error(Import::JiraClient::ApiError)

        expect(WorkPackage.find("DPPP-6").attachments).to be_empty
      end
    end

    context "when the import is aborting" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Import::JiraImport)
          .to receive(:in_state?).with(:import_aborting).and_return(true)
        # rubocop:enable RSpec/AnyInstance
      end

      it "stops iterating and reports the abortion" do
        expect { create_work_package_attachments }.to raise_error(Import::ProgressableJob::AbortionError)
      end
    end
  end
end
