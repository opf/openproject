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

RSpec.describe "Scheduling the IFC model conversion", type: :job, with_config: { edition: "bim" } do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project, enabled_module_names: %i[bim]) }

  let(:conversion_job) { Bim::IfcModels::IfcConversionJob }
  let(:ifc_file) do
    Rack::Test::UploadedFile.new(Rails.root.join("modules/bim/spec/fixtures/files/minimal.ifc").to_s, "application/binary")
  end

  def create_ifc_model(ifc_attachment)
    Bim::IfcModels::CreateService
      .new(user:)
      .call(project:, title: "Model", ifc_attachment:)
      .result
  end

  context "with virus scanning disabled", with_settings: { antivirus_scan_mode: :disabled } do
    it "queues the conversion once the IFC file is stored" do
      ifc_model = create_ifc_model(ifc_file)

      expect(conversion_job).to have_been_enqueued.with(ifc_model)
    end

    it "does not convert a model again that is already converted" do
      ifc_model = create_ifc_model(ifc_file)
      ifc_model.update!(conversion_status: :completed)

      expect { Attachment.find(ifc_model.ifc_attachment.id).notify_file_available }
        .not_to have_enqueued_job(conversion_job)
    end
  end

  context "with virus scanning enabled",
          with_ee: %i[virus_scanning],
          with_settings: { antivirus_scan_mode: :clamav_socket } do
    let(:clamav_client) { instance_double(ClamAV::Client, execute: ClamAV::SuccessResponse.new("OK")) }

    before do
      allow(ClamAV::Client).to receive(:new).and_return(clamav_client)
    end

    it "queues the conversion only once the IFC file is scanned clean" do
      ifc_model = create_ifc_model(ifc_file)

      expect(conversion_job).not_to have_been_enqueued

      Attachments::VirusScanJob.perform_now(ifc_model.ifc_attachment)

      expect(conversion_job).to have_been_enqueued.with(ifc_model)
    end

    context "when the scan fails on the last attempt" do
      let(:clamav_client) { instance_double(ClamAV::Client, execute: ClamAV::ErrorResponse.new("Unavailable")) }

      def scan_on_last_attempt(attachment)
        job = Attachments::VirusScanJob.new(attachment)
        3.times { job.perform_now }
      rescue Attachments::VirusScanJob::VirusScanFailed
        nil
      end

      it "shows the failed scan on the model and does not convert it" do
        ifc_model = create_ifc_model(ifc_file)

        scan_on_last_attempt(ifc_model.ifc_attachment)

        expect(ifc_model.reload).to be_pending
        expect(ifc_model.conversion_error_message).to eq(I18n.t("ifc_models.conversion.virus_scan_failed"))
        expect(conversion_job).not_to have_been_enqueued
      end

      it "converts the model once a rescan succeeds" do
        ifc_model = create_ifc_model(ifc_file)
        scan_on_last_attempt(ifc_model.ifc_attachment)

        allow(clamav_client).to receive(:execute).and_return(ClamAV::SuccessResponse.new("OK"))
        Attachments::VirusScanJob.perform_now(ifc_model.ifc_attachment.reload)

        expect(conversion_job).to have_been_enqueued.with(ifc_model)
      end
    end
  end

  context "with a direct upload", :with_direct_uploads, with_settings: { antivirus_scan_mode: :disabled } do
    include DirectUploadHelpers

    let!(:pending_attachment) do
      create(:attachment, author: user, container: nil, status: :prepared, digest: "")
    end

    before do
      stage_direct_upload(pending_attachment)
    end

    it "queues the conversion only once the direct upload is finished" do
      ifc_model = create_ifc_model(pending_attachment)

      expect(conversion_job).not_to have_been_enqueued

      Attachments::FinishDirectUploadJob.perform_now(pending_attachment.id, allowlist: false)

      expect(conversion_job).to have_been_enqueued.with(ifc_model)
    end
  end
end
