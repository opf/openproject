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

RSpec.describe WorkPackages::ExportJob, "Integration" do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages export_work_packages] })
  end
  let(:export) do
    create(:work_packages_export)
  end
  let(:query) { create(:query, name: "Query report 04/2021 äöü", project:) }
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
  let(:mime_type) { :pdf }

  let(:performed_job) do
    job.tap(&:perform_now)
  end

  subject(:job_status) do
    JobStatus::Status.find_by(job_id: job.job_id)
  end

  describe "with special characters in the project title" do
    let(:project) { create(:project, name: "Foo Bla. Report No. 4/2021 with/for Case 42") }

    it "exports the job correctly, renaming the result" do
      time = DateTime.new(2023, 6, 30, 23, 59)
      allow(DateTime).to receive(:now).and_return(time)

      expect { performed_job }.not_to raise_error

      expect(job_status.status).to eq "success"

      attachment = export.attachments.last
      expected = "Foo_Bla_Report_No._4_2021_with_for_Case_42_Query_report_04_2021__2023-06-30_23-59.pdf"
      expect(attachment.filename).to eq expected
    end
  end

  describe "with overly long project title" do
    let(:project) { create(:project, name: "x" * 255) }

    it "exports the job correctly, limiting the result file length" do
      time = DateTime.new(2023, 6, 30, 23, 59)
      allow(DateTime).to receive(:now).and_return(time)

      expect { performed_job }.not_to raise_error

      expect(job_status.status).to eq "success"

      attachment = export.attachments.last
      expect(attachment.filename.length).to eq 255
      expect(attachment.filename).to end_with "_2023-06-30_23-59.pdf"
    end
  end
end
