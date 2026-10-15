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
require "rack/test"

RSpec.describe "API v3 work package PDF export" do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:type) { create(:type) }
  shared_let(:work_package) { create(:work_package, project:, type:, subject: "A work package") }

  let(:permissions) { %i[view_work_packages] }
  let(:path) { api_v3_paths.work_package_pdf(work_package.id) }

  current_user do
    create(:user, member_with_permissions: { project => permissions })
  end

  subject(:response) { last_response }

  describe "GET /api/v3/work_packages/:id/pdf" do
    context "with the permission to view the work package but not to export work packages" do
      before { get path }

      it "renders the work package as a PDF attachment" do
        expect(response).to have_http_status 200
        expect(response.content_type).to eq "application/pdf"
        expect(response.body).to start_with "%PDF"
        expect(response.headers["Content-Disposition"]).to match(/\Aattachment; filename=".+\.pdf"/)
      end
    end

    context "for a work package the user cannot see" do
      let(:permissions) { [] }

      before { get path }

      it_behaves_like "not found", I18n.t("api_v3.errors.not_found.work_package")
    end

    context "for a non existing work package" do
      let(:path) { api_v3_paths.work_package_pdf(not_existing_id(WorkPackage)) }

      before { get path }

      it_behaves_like "not found", I18n.t("api_v3.errors.not_found.work_package")
    end

    context "when the export fails" do
      let(:exporter) { instance_double(WorkPackage::PDFExport::WorkPackageToPdf) }

      before do
        allow(exporter).to receive(:export!).and_raise(Exports::ExportError.new("Rendering failed."))
        allow(WorkPackage::PDFExport::WorkPackageToPdf).to receive(:new).and_return(exporter)

        get path
      end

      it_behaves_like "error response",
                      500,
                      "InternalServerError",
                      I18n.t("api_v3.errors.code_500")
    end

    describe "template selection" do
      let(:exporter) { instance_double(WorkPackage::PDFExport::Artefact, export!: export_result) }
      let(:export_result) do
        Exports::Result.new(format: :pdf, title: "export.pdf", mime_type: "application/pdf", content: "%PDF-1.4")
      end

      it "renders the requested template" do
        allow(WorkPackage::PDFExport::Artefact).to receive(:new).and_return(exporter)

        get "#{path}?template=artefact"

        expect(response).to have_http_status 200
        expect(WorkPackage::PDFExport::Artefact).to have_received(:new).with(work_package, anything)
      end

      it "defaults to the first template enabled for the type" do
        type.default_variant.pdf_export_templates.toggle("attributes")
        type.default_variant.save!
        allow(WorkPackage::PDFExport::DocumentGenerator).to receive(:new).and_return(exporter)

        get path

        expect(response).to have_http_status 200
        expect(WorkPackage::PDFExport::DocumentGenerator).to have_received(:new).with(work_package, anything)
      end

      it "rejects an unknown template" do
        get "#{path}?template=unknown"

        expect(response).to have_http_status 400
      end

      it "rejects a template disabled for the type" do
        type.default_variant.pdf_export_templates.toggle("artefact")
        type.default_variant.save!

        get "#{path}?template=artefact"

        expect(response).to have_http_status 400
        expect(response.body)
          .to be_json_eql(I18n.t("api_v3.errors.code_400",
                                 message: I18n.t("api_v3.errors.bad_request.pdf_export_template_not_enabled",
                                                 template: "artefact")).to_json)
          .at_path("message")
      end

      it "rejects the export when no template is enabled for the type" do
        type.default_variant.pdf_export_templates.disable_all
        type.default_variant.save!

        get path

        expect(response).to have_http_status 400
        expect(response.body)
          .to be_json_eql(I18n.t("api_v3.errors.code_400",
                                 message: I18n.t("api_v3.errors.bad_request.pdf_export_no_template_enabled")).to_json)
          .at_path("message")
      end
    end

    describe "export options" do
      let(:exporter) { instance_double(WorkPackage::PDFExport::WorkPackageToPdf, export!: export_result) }
      let(:export_result) do
        Exports::Result.new(format: :pdf, title: "export.pdf", mime_type: "application/pdf", content: "%PDF-1.4")
      end

      before do
        allow(WorkPackage::PDFExport::WorkPackageToPdf).to receive(:new).and_return(exporter)
      end

      it "passes the given options to the exporter" do
        get "#{path}?pageOrientation=landscape&footerText=Legal&hyphenation=true&hyphenationLanguage=de"

        expect(WorkPackage::PDFExport::WorkPackageToPdf)
          .to have_received(:new)
          .with(work_package, hash_including(page_orientation: "landscape",
                                             footer_text: "Legal",
                                             hyphenation: true,
                                             hyphenation_language: "de"))
      end

      it "falls back to the settings stored on the type" do
        type.default_variant.pdf_export_templates.update_settings("attributes", "footer_text" => "Stored footer")
        type.default_variant.save!

        get "#{path}?pageOrientation=landscape"

        expect(WorkPackage::PDFExport::WorkPackageToPdf)
          .to have_received(:new)
          .with(work_package, hash_including(footer_text: "Stored footer", page_orientation: "landscape"))
      end

      it "ignores options that do not belong to the selected template" do
        get "#{path}?toc=false"

        expect(WorkPackage::PDFExport::WorkPackageToPdf)
          .to have_received(:new)
          .with(work_package, hash_excluding(:toc))
      end
    end
  end
end
