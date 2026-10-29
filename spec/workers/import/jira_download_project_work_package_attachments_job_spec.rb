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

# The import only produces valid data with semantic identifiers enabled: Jira project keys are
# uppercase, which Projects::Identifier rejects in classic mode.
RSpec.describe Import::JiraDownloadProjectWorkPackageAttachmentsJob,
               :webmock,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with a jira demo issue"
  include_context "with ssrf stubs"

  let(:attachment_content) { Rails.root.join("spec/fixtures/files/airplane-wing-over-cloudy-sky.jpg").binread }
  let(:download_attachment_url) { "https://jira-dc.openproject.org/secure/attachment/10100/airplane-wing-over-cloudy-sky.jpg" }
  let(:work_package) { WorkPackage.find("DPPP-6") }
  let(:attachment) { work_package.attachments.sole }

  before do
    stub_request(:get, download_attachment_url)
      .to_return(status: 200, body: attachment_content, headers: { "Content-Type" => "image/jpg" })

    create_project_role
    create_project
    create_work_packages
  end

  describe "#perform" do
    it "adds the downloaded file to the attachment prepared for it" do
      download_work_package_attachments

      expect(attachment.status).to eq("uploaded")
      expect(File.binread(attachment.diskfile.path)).to eq(attachment_content)
    end

    it "stores the file under the attachment's name rather than the tempfile's" do
      download_work_package_attachments

      expect(attachment.diskfile.path).to end_with("/airplane-wing-over-cloudy-sky.jpg")
    end

    it "keeps the attachment timestamps at the date it was attached in Jira" do
      download_work_package_attachments

      attached_at = Time.zone.parse(jira_issue_payload["fields"]["attachment"].sole["created"])
      expect(attachment).to have_attributes(created_at: attached_at, updated_at: attached_at)
    end

    it "queues the text extraction of the file" do
      expect { download_work_package_attachments }
        .to have_enqueued_job(Attachments::ExtractFulltextJob).with(attachment.id)
    end

    it "keeps the Jira update time on the work package" do
      download_work_package_attachments

      expect(work_package.updated_at).to eq(Time.zone.parse(jira_issue_payload["fields"]["updated"]))
    end

    context "when the file has already been downloaded" do
      before do
        download_work_package_attachments
        Import::JiraImportJobCursor.delete_all
        WebMock.reset_executed_requests!
      end

      it "does not download it again" do
        download_work_package_attachments

        expect(WebMock).not_to have_requested(:get, download_attachment_url)
      end
    end

    context "when the attachment no longer exists" do
      before { attachment.destroy }

      it "skips it" do
        download_work_package_attachments

        expect(WebMock).not_to have_requested(:get, download_attachment_url)
      end
    end

    context "when the download fails with a redirect" do
      before do
        stub_request(:get, download_attachment_url).to_return(
          status: 302, body: "Redirect body.", headers: { "Location" => "https://login.example.com" }
        )
        allow(Rails.logger).to receive(:warn)
      end

      it "logs a warning with context details and continues the import" do
        download_work_package_attachments

        # rubocop:disable-next Layout/LineLength
        expect(Rails.logger).to have_received(:warn).with(
          a_string_including(
            "Could not download jira import attachment, skipping it. Error: Jira API returned error status 302.",
            "STATUS: 302 RESPONSE_BODY: Redirect body. RESPONSE_HEADERS: {\"location\" => [\"https://login.example.com\"]}.",
            "Attachment: {\"id\" => \"10100\", \"size\" => 136426, \"self\" => \"https://jira-dc.openproject.org/rest/api/2/attachment/10100\", \"content\" => \"https://jira-dc.openproject.org/secure/attachment/10100/airplane-wing-over-cloudy-sky.jpg\", \"filename\" => \"airplane-wing-over-cloudy-sky.jpg\", \"mimeType\" => \"image/jpeg\"}.",
            "Backtrace: "
          )
        )
      end

      it "keeps the attachment, marked as failed" do
        download_work_package_attachments

        expect(attachment.status).to eq("import_failed")
      end
    end

    context "when the import is aborting" do
      before do
        # rubocop:disable-next RSpec/AnyInstance
        allow_any_instance_of(Import::JiraImport)
          .to receive(:in_state?).with(:import_aborting).and_return(true)
      end

      it "stops iterating and reports the abortion" do
        expect { download_work_package_attachments }.to raise_error(Import::ProgressableJob::AbortionError)
      end
    end

    context "when the attachment exceeds the maximum filesize",
            with_settings: { attachment_max_size: 0 } do
      it "adds the file bypassing filesize validation" do
        download_work_package_attachments

        expect(attachment.status).to eq("uploaded")
      end
    end
  end

  describe "#progress" do
    subject(:job) { described_class.new(jira_import.id, jira_project.id) }

    context "when no cursor is set" do
      it "returns zeros" do
        expect(job.progress).to eq({ current: 0, total: 0, percentage: 0 })
      end
    end

    context "when cursor is set" do
      let(:jira_attachments) { Import::JiraAttachment.order(:id) }

      before { create_list(:jira_attachment, 2, jira_import:, jira_project:, jira_issue:) }

      it "calculates progress based on cursor position" do
        jira_import.set_job_cursor(job, jira_attachments.second.id)

        expect(job.progress).to eq({ current: 2, total: 3, percentage: 66.67 })
      end

      it "returns 100% when all attachments are processed" do
        jira_import.set_job_cursor(job, jira_attachments.last.id)

        expect(job.progress).to eq({ current: 3, total: 3, percentage: 100.0 })
      end
    end
  end
end
