#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe "NonExistingJobClass" do
  let!(:job_with_non_existing_class) do
    handler = <<~JOB.strip
      --- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
      job_data:
        job_class: WhichShallNotBeNamedJob
        job_id: 8f72c3c9-a1e0-4e46-b0f2-b517288bb76c
        provider_job_id:
        queue_name: default
        priority: 5
        arguments:
        - 42
        executions: 0
        exception_executions: {}
        locale: en
        timezone: UTC
        enqueued_at: '2022-12-05T09:41:39Z'
    JOB
    Delayed::Job.create(handler:)
  end

  before do
    # allow to inspect the job is marked as failed after failure in the test
    allow(Delayed::Worker).to receive(:destroy_failed_jobs).and_return(false)
  end

  it 'does not crash the worker when processed' do
    expect { Delayed::Worker.new(exit_on_complete: true).start }
      .not_to raise_error

    job_with_non_existing_class.reload
    expect(job_with_non_existing_class.last_error).to include("uninitialized constant WhichShallNotBeNamedJob")
    expect(job_with_non_existing_class.failed_at).to be_within(1).of(Time.current)
  end
end
