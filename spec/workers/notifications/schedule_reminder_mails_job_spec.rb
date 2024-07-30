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

RSpec.describe Notifications::ScheduleReminderMailsJob, type: :job do
  let(:scheduled_job) do
    described_class.perform_later.tap do |job|
      set_cron_time(job, job_cron_at)
      GoodJob.perform_inline
    end
  end
  let(:job_cron_at) { Time.current.then { |t| t.change(min: t.min / 15 * 15) } }

  let(:previous_job) do
    described_class.perform_later.tap do |job|
      GoodJob.perform_inline
      set_cron_time(job, previous_job_cron_at)
    end
  end

  let(:ids) { [23, 42] }

  before do
    # We need to access the job as stored in the database to get at the scheduled_at time persisted there
    ActiveJob::Base.disable_test_adapter

    scope = instance_double(ActiveRecord::Relation)
    allow(User).to receive(:having_reminder_mail_to_send).and_return(scope)
    allow(scope).to receive(:pluck).with(:id).and_return(ids)
  end

  def set_cron_time(job, cron_at)
    GoodJob::Job
      .where(id: job.job_id)
      .update_all(cron_at:)
  end

  describe "#perform" do
    shared_examples_for "schedules reminder mails" do
      it "schedules reminder jobs for every user with a reminder mail to be sent" do
        expect { scheduled_job }
          .to change(GoodJob::Job.where(job_class: "Mails::ReminderJob"), :count)
                .by(2)

        arguments_from_both_jobs =
          GoodJob::Job.where(job_class: "Mails::ReminderJob")
                      .flat_map { |i| i.serialized_params["arguments"] }
                      .sort
        expect(arguments_from_both_jobs).to eq(ids)
      end

      it "queries with the intended job execution time (which might have been missed due to high load)" do
        scheduled_job

        expect(User)
          .to have_received(:having_reminder_mail_to_send)
                .with(expected_lower_boundary, expected_upper_boundary)
      end
    end

    context "when there is no predecessor job" do
      it_behaves_like "schedules reminder mails" do
        let(:expected_lower_boundary) { job_cron_at }
        let(:expected_upper_boundary) { job_cron_at }
      end
    end

    context "when there is a predecessor job with a cron_at 15 min before" do
      let(:previous_job_cron_at) { job_cron_at - 15.minutes }

      before do
        previous_job
      end

      it_behaves_like "schedules reminder mails" do
        let(:expected_lower_boundary) { previous_job_cron_at + 15.minutes }
        let(:expected_upper_boundary) { job_cron_at }
      end
    end

    context "when there is a predecessor job with a cron_at 2 hours before" do
      let(:previous_job_cron_at) { job_cron_at - 2.hours }

      before do
        previous_job
      end

      it_behaves_like "schedules reminder mails" do
        let(:expected_lower_boundary) { previous_job_cron_at + 15.minutes }
        let(:expected_upper_boundary) { job_cron_at }
      end
    end

    context "when there is a predecessor job with a cron_at more than 24 hours before" do
      let(:previous_job_cron_at) { job_cron_at - 25.hours }

      before do
        previous_job
      end

      it_behaves_like "schedules reminder mails" do
        let(:expected_lower_boundary) { job_cron_at - 24.hours }
        let(:expected_upper_boundary) { job_cron_at }
      end
    end
  end
end
