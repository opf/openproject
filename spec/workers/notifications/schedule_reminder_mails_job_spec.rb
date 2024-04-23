#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require "spec_helper"

RSpec.describe Notifications::ScheduleReminderMailsJob, type: :job do
  let(:scheduled_job) { described_class.perform_later }
  let(:ids) { [23, 42] }

  before do
    # We need to access the job as stored in the database to get at the scheduled_at time persisted there
    ActiveJob::Base.disable_test_adapter
    scheduled_job

    scope = instance_double(ActiveRecord::Relation)
    allow(User).to receive(:having_reminder_mail_to_send).and_return(scope)
    allow(scope).to receive(:pluck).with(:id).and_return(ids)
  end

  describe "#perform" do
    shared_examples_for "schedules reminder mails" do
      it "schedules reminder jobs for every user with a reminder mails to be sent" do
        expect { GoodJob.perform_inline }.to change(GoodJob::Job, :count).by(2)

        arguments_from_both_jobs =
          GoodJob::Job.where(job_class: "Mails::ReminderJob")
                      .flat_map {|i| i.serialized_params["arguments"]}
                      .sort
        expect(arguments_from_both_jobs).to eq(ids)
      end

      it "queries with the intended job execution time (which might have been missed due to high load)" do
        GoodJob.perform_inline

        expect(User).to have_received(:having_reminder_mail_to_send).with(scheduled_job.job_scheduled_at)
      end
    end

    it_behaves_like "schedules reminder mails"

    context "with a job that missed some runs" do
      before do
        GoodJob::Job
          .where(id: scheduled_job.job_id)
          .update_all(scheduled_at: scheduled_job.job_scheduled_at - 3.hours)
      end

      it_behaves_like "schedules reminder mails"
    end
  end
end
