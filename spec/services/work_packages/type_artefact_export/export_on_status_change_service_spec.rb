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

RSpec.describe WorkPackages::TypeArtefactExport::ExportOnStatusChangeService do
  shared_let(:status_new) { create(:status, name: "New") }
  shared_let(:status_approved) { create(:status, name: "Approved") }
  shared_let(:type) { create(:type, name: "Deliverable") }
  shared_let(:current_user) { create(:admin, lastname: "current_user") }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:project) { create(:project, name: "Important Project", types: [type]) }

  shared_let(:work_package) do
    create(:work_package, project:, type:, status: status_new, subject: "A deliverable")
  end

  let(:instance) { described_class.new(current_user:, work_package:) }
  let(:changes) { { "status_id" => [status_new.id, status_approved.id] } }

  before do
    login_as current_user
  end

  describe "#call!" do
    context "when the type has artefact export disabled (default off)" do
      it "does not export" do
        allow(User).to receive(:execute_as_admin)

        instance.call!(changes:)

        expect(User).not_to have_received(:execute_as_admin)
      end
    end

    context "when status_id is not part of the changes" do
      let(:changes) { { "subject" => %w[a b] } }

      before { type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT) }

      it "does not export" do
        allow(User).to receive(:execute_as_admin)

        instance.call!(changes:)

        expect(User).not_to have_received(:execute_as_admin)
      end
    end

    context "when the work package is the creation wizard artifact work package" do
      before do
        type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT)
        project.update!(project_creation_wizard_artifact_work_package_id: work_package.id)
      end

      it "does not export (handled by the creation wizard service)" do
        allow(User).to receive(:execute_as_admin)

        instance.call!(changes:)

        expect(User).not_to have_received(:execute_as_admin)
      end
    end

    context "when the mode is 'attachment'" do
      before { type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT) }

      it "adds the generated PDF as an attachment to the work package" do
        expect { instance.call!(changes:) }
          .to change { work_package.reload.attachments.count }.by(1)

        attachment = work_package.attachments.last
        expect(attachment.content_type).to eq("application/pdf")
        expect(attachment.filename).to end_with(".pdf")
        expect(attachment.author).to eq(current_user)
      end

      it "journalizes the work package so the attachment shows up in the Activity tab" do
        expect { instance.call!(changes:) }
          .to change { work_package.reload.journals.count }.by(1)

        expect(work_package.last_journal.attachable_journals.map(&:attachment))
          .to include(work_package.attachments.last)
      end
    end

    context "when the mode is 'file_link'" do
      let(:storage) { create(:nextcloud_storage_with_local_connection) }
      let!(:project_storage) do
        create(:project_storage, :as_automatically_managed, project:, storage:)
      end
      let(:service_result) { ServiceResult.success(result: nil) }

      before do
        type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::FILE_LINK)
        allow(Storages::UploadFileService).to receive(:call).and_return(service_result)
      end

      it "uploads the generated PDF to the project's Nextcloud storage" do
        instance.call!(changes:)

        expect(work_package.reload.attachments.count).to eq(0)
        expect(Storages::UploadFileService)
          .to have_received(:call)
          .with(container: work_package,
                project_storage:,
                file_path: type.name,
                filename: /\.pdf\z/,
                file_data: instance_of(StringIO))
      end

      context "when the type name contains path/forbidden characters" do
        before { type.update!(name: "Feature/Bug") }

        it "sanitizes the folder name so it cannot inject nested folders" do
          instance.call!(changes:)

          expect(Storages::UploadFileService)
            .to have_received(:call)
            .with(container: work_package,
                  project_storage:,
                  file_path: a_string_matching(%r{\AFeature[^/]Bug\z}),
                  filename: /\.pdf\z/,
                  file_data: instance_of(StringIO))
        end
      end

      context "and the upload fails" do
        let(:service_result) do
          ServiceResult.failure(result: nil).tap { |r| r.errors.add(:base, "boom") }
        end

        it "logs the failure and does not raise" do
          allow(Rails.logger).to receive(:error)

          expect { instance.call!(changes:) }.not_to raise_error
          expect(Rails.logger).to have_received(:error).with(/Artefact upload failed/)
        end
      end

      context "without a Nextcloud storage on the project" do
        let!(:project_storage) { nil }

        it "skips the upload and logs" do
          allow(Rails.logger).to receive(:info)

          instance.call!(changes:)

          expect(Storages::UploadFileService).not_to have_received(:call)
          expect(Rails.logger).to have_received(:info).with(/skipping artefact upload/)
        end
      end
    end

    context "when the type has stored artefact export settings" do
      before do
        type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT)
        type.default_variant.pdf_export_templates.update_settings(
          "artefact", "toc" => "false", "hyphenation" => "true", "hyphenation_language" => "de"
        )
        type.default_variant.save!
      end

      it "passes the stored settings to the exporter" do
        allow(WorkPackage::PDFExport::Artefact).to receive(:new).and_call_original

        instance.call!(changes:)

        expect(WorkPackage::PDFExport::Artefact)
          .to have_received(:new)
                .with(work_package, hash_including(toc: "false", hyphenation: "true", hyphenation_language: "de"))
      end
    end

    context "when the type has no stored artefact export settings" do
      before { type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT) }

      it "passes an empty options hash, behaving exactly as before this feature" do
        allow(WorkPackage::PDFExport::Artefact).to receive(:new).and_call_original

        instance.call!(changes:)

        expect(WorkPackage::PDFExport::Artefact).to have_received(:new).with(work_package, {})
      end
    end

    context "when PDF generation raises" do
      let(:pdf_export) { instance_double(WorkPackage::PDFExport::Artefact) }

      before do
        type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT)
        allow(WorkPackage::PDFExport::Artefact).to receive(:new).and_return(pdf_export)
        allow(pdf_export).to receive(:export!).and_raise(Exports::ExportError, "kaboom")
      end

      it "rescues and logs the error" do
        allow(Rails.logger).to receive(:error)

        expect { instance.call!(changes:) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Artefact export failed/)
      end
    end

    context "when the project resolves the type to a variant", with_flag: { type_variants: true } do
      shared_let(:variant) { create(:type_variant, type:, variant_name: "Signed deliverable") }

      shared_let(:variant_project) do
        create(:project, name: "Variant Project", types: [variant])
      end
      shared_let(:variant_work_package) do
        create(:work_package, project: variant_project, type:, status: status_new, subject: "A deliverable")
      end

      let(:instance) { described_class.new(current_user:, work_package: variant_work_package) }

      before do
        unlink_configuration(variant, aspect: TypeVariant::PDF_EXPORT)
      end

      context "when the variant enables the export and the root does not" do
        before do
          type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::OFF)
          variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT)
        end

        it "exports, following the variant rather than the stored root" do
          expect { instance.call!(changes:) }
            .to change { variant_work_package.reload.attachments.count }.by(1)
        end
      end

      context "when the variant disables the export and the root enables it" do
        before do
          type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT)
          variant.update!(artefact_export_mode: Type::ArtefactExport::OFF)
        end

        it "does not export" do
          expect { instance.call!(changes:) }
            .not_to change { variant_work_package.reload.attachments.count }
        end
      end

      context "when the variant has stored artefact export settings and the root does not" do
        before do
          type.default_variant.update!(artefact_export_mode: Type::ArtefactExport::OFF)
          variant.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT)
          variant.pdf_export_templates.update_settings("artefact", "toc" => "false")
          variant.save!
        end

        it "resolves the settings from the variant, not the stored root" do
          allow(WorkPackage::PDFExport::Artefact).to receive(:new).and_call_original

          instance.call!(changes:)

          expect(WorkPackage::PDFExport::Artefact)
            .to have_received(:new)
                  .with(variant_work_package, hash_including(toc: "false"))
        end
      end
    end
  end
end
