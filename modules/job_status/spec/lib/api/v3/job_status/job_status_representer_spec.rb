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

class NoOpJob < ApplicationJob
  discard_on StandardError

  def store_status? = true

  def perform(fail: false)
    raise StandardError if fail

    "I'll do nothing"
  end
end

RSpec.describe API::V3::JobStatus::JobStatusRepresenter do
  let(:user) { build_stubbed(:admin) }

  describe "status", with_good_job_batches: [NoOpJob] do
    subject(:status_json) { described_class.new(job_status, current_user: user).to_json }

    context "when job is not part of a batch" do
      let(:job) { NoOpJob.perform_later }
      let(:job_status) { JobStatus::Status.find_by(job_id: job.job_id) }

      it_behaves_like "property", :status do
        let(:value) { "in_queue" }
      end

      it 'returns "succeeded" if the job has finished successfully' do
        job = NoOpJob.perform_later
        GoodJob.perform_inline
        status = JobStatus::Status.find_by(job_id: job.job_id)

        status_json = described_class.new(status, current_user: user).to_json
        expect(status_json).to be_json_eql("success".to_json).at_path("status")
      end
    end

    context "when job is part of a batch" do
      it "returns in_process if the batch is running" do
        GoodJob::Batch.enqueue { NoOpJob.perform_later }
        status = JobStatus::Status.order(:created_at).last
        status_json = described_class.new(status, current_user: user).to_json

        expect(status_json).to be_json_eql("in_queue".to_json).at_path("status")
      end

      it "returns success if the batch has finished and is successful" do
        GoodJob::Batch.enqueue { NoOpJob.perform_later }
        GoodJob.perform_inline
        status = JobStatus::Status.order(:created_at).last

        status_json = described_class.new(status, current_user: user).to_json
        expect(status_json).to be_json_eql("success".to_json).at_path("status")
      end

      it "returns failure if the batch has finished and has been discarded" do
        GoodJob::Batch.enqueue { NoOpJob.perform_later(fail: true) }
        begin
          GoodJob.perform_inline
        rescue StandardError
          # noop
        end
        status = JobStatus::Status.order(:created_at).last

        status_json = described_class.new(status, current_user: user).to_json
        expect(status_json).to be_json_eql("failure".to_json).at_path("status")
      end
    end
  end
end
