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

RSpec.describe Attachments::FinishDirectUploadJob, "integration", :with_direct_uploads, type: :job do
  include DirectUploadHelpers

  shared_let(:user) { create(:admin) }

  let!(:pending_attachment) do
    create(:attachment,
           author: user,
           status: :prepared,
           digest: "",
           container:)
  end

  let(:job) { described_class.new }

  before do
    stage_direct_upload(pending_attachment)
  end

  def stored_content
    File.read(Attachment.find(pending_attachment.id).diskfile.path)
  end

  shared_examples_for "completing direct upload of attachment" do |expect_extract_fulltext_job: true|
    it "turns the pending attachment into a standard attachment" do
      job.perform(pending_attachment.id)

      attachment = Attachment.find(pending_attachment.id)

      expect(attachment.status).to eq "uploaded"
      expect(attachment.downloads)
        .to be(0)
      # expect to replace the content type with the actual value
      expect(attachment.content_type)
        .to eql("text/plain")
      expect(attachment.digest)
        .to eql("9473fdd0d880a43c21b7778d34872157")
    end

    it "adds a journal to the attachment in the name of the attachment's author" do
      job.perform(pending_attachment.id)

      journals = Attachment.find(pending_attachment.id).journals

      expect(journals.count)
        .to be(2)

      expect(journals.last.user)
        .to eql(pending_attachment.author)
    end

    if expect_extract_fulltext_job
      it "enqueues the ExtractFulltextJob job" do
        clear_enqueued_jobs

        job.perform(pending_attachment.id)

        expect(Attachments::ExtractFulltextJob)
          .to have_been_enqueued
          .with(pending_attachment.id)
      end
    else
      it "does not enqueue the ExtractFulltextJob job" do
        clear_enqueued_jobs

        job.perform(pending_attachment.id)

        expect(Attachments::ExtractFulltextJob)
          .not_to have_been_enqueued
      end
    end

    context "when antivirus scan is disabled (default)",
            with_settings: { antivirus_scan_mode: :disabled } do
      it "does not enqueue the VirusScanJob job" do
        clear_enqueued_jobs

        job.perform(pending_attachment.id)

        expect(Attachments::VirusScanJob)
          .not_to have_been_enqueued
      end
    end

    context "when antivirus scan is enabled",
            with_ee: %i[virus_scanning],
            with_settings: { antivirus_scan_mode: :clamav_socket } do
      it "enqueues the VirusScanJob job" do
        clear_enqueued_jobs

        job.perform(pending_attachment.id)

        expect(Attachments::VirusScanJob)
          .to have_been_enqueued
          .with(pending_attachment)
      end
    end
  end

  context "for a journalized container" do
    let!(:container) { create(:work_package) }
    let!(:container_timestamp) { container.updated_at }

    it_behaves_like "completing direct upload of attachment"

    it "adds a journal to the container in the name of the attachment's author" do
      job.perform(pending_attachment.id)

      journals = container.journals.reload

      expect(journals.count)
        .to be(2)

      expect(journals.last.user)
        .to eql(pending_attachment.author)

      expect(journals.last.created_at > container_timestamp)
        .to be_truthy

      container.reload

      expect(container.lock_version)
        .to be 0
    end

    it "deletes the staged upload" do
      job.perform(pending_attachment.id)

      expect(staged_direct_upload(pending_attachment)).to be_nil
    end

    context "without a staged upload" do
      before do
        staged_direct_upload(pending_attachment).destroy
      end

      it "removes the pending attachment" do
        allow(OpenProject.logger).to receive(:error)

        job.perform(pending_attachment.id)

        expect { pending_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signed upload form is replayed after completion" do
      it "keeps the completed content" do
        job.perform(pending_attachment.id)
        stage_direct_upload(pending_attachment, content: "replayed content")
        job.perform(pending_attachment.id)

        expect(stored_content).to eq "test content"
        expect(Attachment.find(pending_attachment.id).digest)
          .to eql("9473fdd0d880a43c21b7778d34872157")
      end
    end

    context "when another completion finished first" do
      it "does not complete the upload again" do
        stale_attachment = Attachment.find(pending_attachment.id)
        job.perform(pending_attachment.id)
        stage_direct_upload(pending_attachment, content: "replayed content")

        result = Attachments::FinishDirectUploadService.new(user:, model: stale_attachment).call

        expect(result).to be_failure
        expect(stored_content).to eq "test content"
      end

      it "keeps the completed attachment when a concurrent job loses the race" do
        job.perform(pending_attachment.id)
        allow(Attachment)
          .to receive(:pending_direct_upload)
          .and_return(Attachment.where(id: pending_attachment.id))

        job.perform(pending_attachment.id)

        expect(Attachment.find(pending_attachment.id)).to be_status_uploaded
      end
    end

    describe "attachment created event" do
      let(:attachment_ids) { [] }

      let!(:subscription) do
        OpenProject::Notifications.subscribe(OpenProject::Events::ATTACHMENT_CREATED) do |payload|
          attachment_ids << payload[:attachment].id
        end
      end

      after do
        OpenProject::Notifications.unsubscribe(OpenProject::Events::ATTACHMENT_CREATED, subscription)
      end

      it "is triggered" do
        job.perform(pending_attachment.id)
        pending_attachment.reload
        expect(attachment_ids).to include(pending_attachment.id)
      end
    end
  end

  context "for a non journalized container" do
    let!(:container) { create(:wiki_page) }

    it_behaves_like "completing direct upload of attachment", expect_extract_fulltext_job: false
  end

  context "for a nil container" do
    let!(:container) { nil }

    it_behaves_like "completing direct upload of attachment"
  end

  context "for an attachment that has been removed in the meantime" do
    let!(:container) { create(:work_package) }

    it "logs the error and resolves the job as done" do
      allow(OpenProject.logger).to receive(:error)

      job.perform(pending_attachment.id + 1)

      expect(OpenProject.logger).to have_received(:error)
    end
  end

  context "with an incompatible attachment allowlist",
          with_settings: { attachment_whitelist: %w[image/png] } do
    let!(:container) { create(:work_package) }
    let!(:container_timestamp) { container.updated_at }

    it "does not save the attachment" do
      allow(pending_attachment).to receive(:save!)
      allow(OpenProject.logger).to receive(:error)

      job.perform(pending_attachment.id)

      expect(pending_attachment).not_to have_received(:save!)
      expect(OpenProject.logger).to have_received(:error)

      container.reload

      expect(container.attachments).to be_empty
      expect { pending_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "removes the staged upload together with the attachment" do
      allow(OpenProject.logger).to receive(:error)

      job.perform(pending_attachment.id)

      expect(staged_direct_upload(pending_attachment)).to be_nil
    end

    context "when the job is getting a allowlist override" do
      it "does save the attachment" do
        job.perform(pending_attachment.id, allowlist: false)

        container.reload

        expect(container.attachments.count).to eq 1
        expect { pending_attachment.reload }.not_to raise_error

        expect(pending_attachment.downloads).to eq 0
      end
    end
  end

  context "with the user not being allowed",
          with_settings: { attachment_whitelist: %w[image/png] } do
    shared_let(:user) { create(:user) }
    let!(:container) { create(:work_package) }

    it "does not save the attachment" do
      allow(pending_attachment).to receive(:save!)

      job.perform(pending_attachment.id)

      expect(pending_attachment).not_to have_received(:save!)

      expect { pending_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
