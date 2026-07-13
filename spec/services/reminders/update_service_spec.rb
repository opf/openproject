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
require "services/base_services/behaves_like_update_service"

RSpec.describe Reminders::UpdateService do
  it_behaves_like "BaseServices update service" do
    let(:factory) { :reminder }
  end

  describe "remind_at changed" do
    subject { described_class.new(user:, model: model_instance).call(call_attributes) }

    let(:business_day_at_noon) { Time.zone.local(2025, 1, 8, 12, 0, 0) }
    let(:model_instance) { create(:reminder, :scheduled, :with_unread_notifications, creator: user) }
    let(:user) { create(:admin) }
    let(:remind_at) { business_day_at_noon + 2.days }
    let(:call_attributes) { { remind_at_date: remind_at.to_date, remind_at_time: remind_at.strftime("%H:%M") } }

    before do
      travel_to(business_day_at_noon)
      model_instance.update!(job_id: 1)
      allow(Reminders::ScheduleReminderJob).to receive(:schedule)
        .with(model_instance)
        .and_return(instance_double(Reminders::ScheduleReminderJob, job_id: 2))
    end

    after do
      travel_back
    end

    context "with an existing unfinished scheduled job" do
      let(:job) { instance_double(GoodJob::Job, finished?: false, destroy: true) }

      before do
        allow(GoodJob::Job).to receive(:find_by).and_return(job)
      end

      it "reschedules the reminder" do
        expect { subject }.to change(model_instance, :job_id).from("1").to("2")

        aggregate_failures "destroy existing job" do
          expect(GoodJob::Job).to have_received(:find_by).with(id: "1")
          expect(job).to have_received(:destroy)
        end

        aggregate_failures "marks unread notifications as read" do
          expect(model_instance.notifications.count).to eq(1)
          expect(model_instance.unread_notifications.count).to eq(0)
        end

        aggregate_failures "schedule new job" do
          expect(model_instance.remind_at.to_i).to eq(remind_at.to_i)
          expect(Reminders::ScheduleReminderJob).to have_received(:schedule).with(model_instance)
        end
      end
    end

    context "with an existing finished scheduled job" do
      let(:job) { instance_double(GoodJob::Job, finished?: true, destroy: true) }

      before do
        allow(GoodJob::Job).to receive(:find_by).and_return(job)
      end

      it "schedules a new job" do
        expect { subject }.to change(model_instance, :job_id).from("1").to("2")

        aggregate_failures "does NOT destroy existing job" do
          expect(GoodJob::Job).to have_received(:find_by).with(id: "1")
          expect(job).not_to have_received(:destroy)
        end

        aggregate_failures "schedule new job" do
          expect(model_instance.remind_at.to_i).to eq(remind_at.to_i)
          expect(Reminders::ScheduleReminderJob).to have_received(:schedule).with(model_instance)
        end
      end
    end

    context "with remind_at attribute in non-utc timezone" do
      let(:call_attributes) { { remind_at: remind_at.in_time_zone("Africa/Nairobi") } }

      it "reschedules the reminder" do
        expect { subject }.to change(model_instance, :job_id).from("1").to("2")

        aggregate_failures "schedule new job" do
          expect(model_instance.remind_at.to_i).to eq(call_attributes[:remind_at].to_i)
          expect(Reminders::ScheduleReminderJob).to have_received(:schedule).with(model_instance)
        end
      end
    end
  end

  describe "unchangeable attributes" do
    let(:original_creator) { create(:user) }
    let(:original_remindable) { create(:work_package) }
    let(:model_instance) { create(:reminder, creator: original_creator, remindable: original_remindable) }

    context "when attempting to update the creator" do
      subject { described_class.new(user: model_instance.creator, model: model_instance).call(creator: another_user) }

      let(:another_user) { create(:user) }

      it "does not update the creator", :aggregate_failures do
        update_svc = subject

        expect(update_svc).to be_a_failure
        expect(update_svc.result.reload.creator).to eq(original_creator)
        expect(update_svc.message).to eq("Creator is invalid. may not be accessed. cannot be changed.")
      end
    end

    context "when attempting to update the remindable" do
      subject { described_class.new(user: model_instance.creator, model: model_instance).call(remindable: another_remindable) }

      let(:another_remindable) { create(:work_package) }

      it "does not update the remindable", :aggregate_failures do
        update_svc = subject

        expect(update_svc).to be_a_failure
        expect(update_svc.result.reload.remindable).to eq(original_remindable)
        expect(update_svc.message).to include("cannot be changed.")
      end
    end
  end
end
