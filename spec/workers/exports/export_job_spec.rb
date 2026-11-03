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

RSpec.describe Exports::ExportJob, with_good_job_batches: [Exports::ExportJob] do
  let(:job_class) do
    stub_const("InterruptedExportJobMock", Class.new(described_class) do
      def prepare!
        raise "Must not run after an interrupted run"
      end
    end)
  end
  let(:export) { WorkPackages::Export.create! }
  let!(:job) { job_class.perform_later(export:, user: User.system, mime_type: :csv, query: nil) }

  def restart_after_killed_run
    GoodJob::Job.where(id: job.job_id).update_all(performed_at: Time.current)
    GoodJob.perform_inline(limit: 1)
  end

  it "retries the export once and then fails it" do
    allow(Rails.error).to receive(:report)

    restart_after_killed_run
    expect(GoodJob::Job.find(job.job_id)).to have_attributes(performed_at: nil, finished_at: nil)
    expect(export.job_status).to have_attributes(status: "in_queue")
    expect(Rails.error)
      .to have_received(:report)
      .with(an_instance_of(GoodJob::InterruptError), source: "application.active_job")

    expect { restart_after_killed_run }.to raise_error(GoodJob::InterruptError)
    expect(GoodJob::Job.find(job.job_id))
      .to have_attributes(finished_at: be_present, error: include("GoodJob::InterruptError"))
    expect(export.job_status.reload).to have_attributes(status: "failure")
  end
end
