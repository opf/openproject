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

RSpec.describe WorkPackages::ExportJob do
  let(:user) { build_stubbed(:user) }
  let(:attachment) { double("Attachment", id: 1234) }
  let(:export) do
    create(:work_packages_export)
  end
  let(:query) { build_stubbed(:query) }
  let(:query_attributes) { {} }

  let(:job) { described_class.new(**jobs_args) }
  let(:jobs_args) do
    {
      export:,
      mime_type:,
      user:,
      options:,
      query:,
      query_attributes:
    }
  end
  let(:options) { {} }

  subject do
    job.tap(&:perform_now)
  end

  shared_examples_for "exporter returning string" do
    let(:result) do
      Exports::Result.new(format: "blubs",
                          title: "some_title.#{mime_type}",
                          content: "some string",
                          mime_type: "application/octet-stream")
    end

    let(:service) { double("attachments create service") } # rubocop:disable RSpec/VerifiedDoubles
    let(:exporter_instance) { instance_double(exporter) }

    it "exports" do
      expect(Attachments::CreateService)
        .to receive(:bypass_whitelist)
              .with(user:)
              .and_return(service)

      expect(Exports::CleanupOutdatedJob)
        .to receive(:perform_after_grace)

      expect(service)
        .to receive(:call) do |file:, **_args|
        expect(File.basename(file))
          .to start_with "some_title"

        expect(File.basename(file))
          .to end_with ".#{mime_type}"

        ServiceResult.success(result: attachment)
      end

      allow(exporter).to receive(:new).and_return exporter_instance

      allow(exporter_instance).to receive(:export!).and_return(result)

      # expect to create a status
      expect(subject.job_status).to be_present
      expect(subject.job_status.reference).to eq export
      expect(subject.job_status[:status]).to eq "success"
      expect(subject.job_status[:payload]["download"]).to eq "/api/v3/attachments/1234/content"
    end
  end

  describe "query passing" do
    context "when passing in group_by through attributes" do
      let(:query_attributes) { { group_by: "assigned_to" } }
      let(:mime_type) { :pdf }
      let(:exporter) { WorkPackage::PDFExport::WorkPackageListToPdf }

      it "updates the query from attributes" do
        allow(exporter)
          .to receive(:new) do |query, _options|
          expect(query.group_by).to eq "assigned_to"
        end
          .and_call_original

        subject
      end
    end
  end

  describe "#perform" do
    context "with the pdf mime type" do
      let(:mime_type) { :pdf }
      let(:exporter) { WorkPackage::PDFExport::WorkPackageListToPdf }

      it_behaves_like "exporter returning string"
    end

    context "with the csv mime type" do
      let(:mime_type) { :csv }
      let(:exporter) { WorkPackage::Exports::CSV }

      it_behaves_like "exporter returning string"
    end
  end
end
