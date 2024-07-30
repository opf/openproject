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

RSpec.describe Notifications::ScheduleDateAlertsNotificationsJob, type: :job, with_ee: %i[date_alerts] do
  shared_let(:project) { create(:project, name: "main") }
  # Paris and Berlin are both UTC+01:00 (CET) or UTC+02:00 (CEST)
  shared_let(:timezone_paris) { ActiveSupport::TimeZone["Europe/Paris"] }
  # Kathmandu is UTC+05:45 (no DST)
  shared_let(:timezone_kathmandu) { ActiveSupport::TimeZone["Asia/Kathmandu"] }
  shared_let(:user_paris) do
    create(:user,
           firstname: "Paris",
           preferences: { time_zone: timezone_paris.name })
  end
  shared_let(:user_kathmandu) do
    create(:user,
           firstname: "Kathmandu",
           preferences: { time_zone: timezone_kathmandu.name })
  end

  let(:scheduled_job) { described_class.perform_later }
  let(:scheduled_predecessor_job) do
    described_class.perform_later.tap do
      GoodJob.perform_inline
    end
  end

  before do
    ActiveJob::Base.disable_test_adapter
  end

  def set_predecessor_cron_time(cron_at)
    GoodJob::Job
      .where(id: scheduled_predecessor_job.job_id)
      .update_all(cron_at:)
  end

  def set_cron_time(cron_at)
    GoodJob::Job
      .where(id: scheduled_job.job_id)
      .update_all(cron_at:)
  end

  def set_scheduled_at_time(scheduled_at)
    GoodJob::Job
      .where(id: scheduled_job.job_id)
      .update_all(scheduled_at:)
  end

  # Converts "hh:mm" into { hour: h, min: m }
  def time_hash(time)
    %i[hour min].zip(time.split(":", 2).map(&:to_i)).to_h
  end

  def timezone_time(time, timezone)
    timezone.now.change(time_hash(time))
  end

  def run_job(cron_at:, local_time:, timezone:, scheduled_at: cron_at)
    set_cron_time(timezone_time(cron_at, timezone))
    set_scheduled_at_time(timezone_time(scheduled_at, timezone))

    travel_to(timezone_time(local_time, timezone)) do
      GoodJob.perform_inline

      yield if block_given?
    end
  end

  def deserialize_job(job)
    deserializer_class = Class.new { include(ActiveJob::Arguments) }
    deserializer_class.new
                      .deserialize(job.serialized_params)
                      .to_h
  end

  def expect_job(job, *arguments)
    job_data = deserialize_job(job)
    expect(job_data["job_class"]).to eql(job.job_class)
    expect(job_data["arguments"]).to match_array arguments
    expect(job_data["executions"]).to eq 0
  end

  shared_examples_for "job execution creates date alerts creation job" do
    let(:job_class) { Notifications::CreateDateAlertsNotificationsJob.name }

    before do
      set_predecessor_cron_time(timezone_time(predecessor_cron_at, timezone)) if defined?(predecessor_cron_at)
    end

    it "creates the job for the user" do
      expect do
        run_job(timezone:,
                cron_at:,
                scheduled_at: defined?(scheduled_at) ? scheduled_at : cron_at,
                local_time:) do
          j = GoodJob::Job.where(job_class:)
                          .order(created_at: :desc)
                          .last
          expect_job(j, user)
        end
      end.to change { GoodJob::Job.where(job_class:).count }.by 1
    end
  end

  shared_examples_for "job execution creates no date alerts creation job" do
    before do
      set_predecessor_cron_time(timezone_time(predecessor_cron_at, timezone)) if defined?(predecessor_cron_at)
    end

    it "creates no job" do
      expect do
        run_job(timezone:,
                cron_at:,
                scheduled_at: defined?(scheduled_at) ? scheduled_at : cron_at,
                local_time:)
      end.not_to change { GoodJob::Job.where(job_class: Notifications::CreateDateAlertsNotificationsJob.name).count }
    end
  end

  describe "#perform_later" do
    it "only one can be scheduled at a time" do
      scheduled_job

      expect(described_class.perform_later).to be_falsey
    end
  end

  describe "#perform" do
    context "for users whose local time is 1:00 am (UTC+1) when the job is executed" do
      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:04" }
        let(:user) { user_paris }
      end
    end

    context "for users whose local time is 1:00 am (UTC+05:45) when the job is executed" do
      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_kathmandu }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:04" }
        let(:user) { user_kathmandu }
      end
    end

    context "without enterprise token", with_ee: false do
      it_behaves_like "job execution creates no date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:04" }
      end
    end

    context "when cron-ed, scheduled and executed at 01:00 am local time" do
      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:00" }
        let(:user) { user_paris }
      end
    end

    context "when cron-ed at 1:00 am but scheduled and executed at 01:14 am local time" do
      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:scheduled_at) { "1:14" }
        let(:local_time) { "1:14" }
        let(:user) { user_paris }
      end
    end

    context "when cron-ed, scheduled and executed at 01:15 am local time" do
      it_behaves_like "job execution creates no date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:15" }
        let(:scheduled_at) { "1:15" }
        let(:local_time) { "1:15" }
      end
    end

    context "when cron-ed and scheduled at 01:00 am local time and executed at 01:37 am local time" do
      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:scheduled_at) { "1:00" }
        let(:local_time) { "1:37" }
        let(:user) { user_paris }
      end
    end

    context "when cron-ed at 01:00 am but rescheduled to 1:15 and executed at 01:37 am local time" do
      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:scheduled_at) { "1:15" }
        let(:local_time) { "1:37" }
        let(:user) { user_paris }
      end
    end

    context "when cron-ed at 00:45 am but rescheduled to 1:15 and executed at 01:37 am local time" do
      it_behaves_like "job execution creates no date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "0:45" }
        let(:scheduled_at) { "1:15" }
        let(:local_time) { "1:37" }
      end
    end

    context "when cron-ed, scheduled and executed at 01:15 am and the predecessor being cron-ed to 0:30 am" do
      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:15" }
        let(:predecessor_cron_at) { "0:30" }
        let(:scheduled_at) { "1:15" }
        let(:local_time) { "1:15" }
        let(:user) { user_paris }
      end
    end

    context "when cron-ed, scheduled and executed at 01:15 am and the predecessor being cron-ed to 1:00 am" do
      it_behaves_like "job execution creates no date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:15" }
        let(:predecessor_cron_at) { "1:00" }
        let(:scheduled_at) { "1:15" }
        let(:local_time) { "1:15" }
      end
    end

    context "with a user having only due_date active in notification settings" do
      before do
        NotificationSetting
          .where(user: user_paris)
          .update_all(due_date: 1,
                      start_date: nil,
                      overdue: nil)
      end

      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:00" }
        let(:user) { user_paris }
      end
    end

    context "with a user having only start_date active in notification settings" do
      before do
        NotificationSetting
          .where(user: user_paris)
          .update_all(due_date: nil,
                      start_date: 1,
                      overdue: nil)
      end

      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:00" }
        let(:user) { user_paris }
      end
    end

    context "with a user having only overdue active in notification settings" do
      before do
        NotificationSetting
          .where(user: user_paris)
          .update_all(due_date: nil,
                      start_date: nil,
                      overdue: 1)
      end

      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:00" }
        let(:user) { user_paris }
      end
    end

    context "without a user having notification settings" do
      before do
        NotificationSetting
          .where(user: user_paris)
          .update_all(due_date: nil,
                      start_date: nil,
                      overdue: nil)
      end

      it_behaves_like "job execution creates no date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:00" }
      end
    end

    context "with a user having only a project active notification settings" do
      before do
        NotificationSetting
          .where(user: user_paris)
          .update_all(due_date: nil,
                      start_date: nil,
                      overdue: nil)

        NotificationSetting
          .create(user: user_paris,
                  project: create(:project),
                  due_date: 1,
                  start_date: nil,
                  overdue: nil)
      end

      it_behaves_like "job execution creates date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:00" }
        let(:user) { user_paris }
      end
    end

    context "with a locked user" do
      before do
        user_paris.locked!
      end

      it_behaves_like "job execution creates no date alerts creation job" do
        let(:timezone) { timezone_paris }
        let(:cron_at) { "1:00" }
        let(:local_time) { "1:00" }
      end
    end
  end
end
