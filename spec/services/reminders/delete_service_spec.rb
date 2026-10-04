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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "services/base_services/behaves_like_delete_service"

RSpec.describe Reminders::DeleteService do
  it_behaves_like "BaseServices delete service" do
    let(:factory) { :reminder }

    before do
      allow(model_instance).to receive(:update).and_return(model_destroy_result)
    end
  end

  describe "Remove reminder" do
    subject { described_class.new(user:, model: model_instance).call }

    let(:model_instance) { create(:reminder, :scheduled, :with_unread_notifications, creator: user) }
    let(:user) { create(:admin) }

    context "with an existing unfinished scheduled job" do
      let(:job) { instance_double(GoodJob::Job, finished?: false, destroy: true) }

      before do
        model_instance.update(job_id: 1, completed_at: nil)
        allow(GoodJob::Job).to receive(:find_by).and_return(job)
      end

      it "completes the reminder" do
        expect { subject }.to change(model_instance, :completed_at).from(nil)

        aggregate_failures "destroy existing job" do
          expect(GoodJob::Job).to have_received(:find_by).with(id: "1")
          expect(job).to have_received(:destroy)
        end

        aggregate_failures "marks unread notifications as read" do
          expect(model_instance.notifications.count).to eq(1)
          expect(model_instance.unread_notifications.count).to eq(0)
        end

        aggregate_failures "marks the reminder as complete" do
          expect(model_instance).to be_completed
        end
      end
    end

    context "with an existing finished scheduled job" do
      let(:job) { instance_double(GoodJob::Job, finished?: true, destroy: true) }

      before do
        model_instance.update(job_id: 1, completed_at: nil)
        allow(GoodJob::Job).to receive(:find_by).and_return(job)
      end

      it "completes the reminder" do
        expect { subject }.to change(model_instance, :completed_at).from(nil)

        aggregate_failures "does NOT destroy existing job" do
          expect(GoodJob::Job).to have_received(:find_by).with(id: "1")
          expect(job).not_to have_received(:destroy)
        end

        aggregate_failures "marks the reminder as complete" do
          expect(model_instance).to be_completed
        end
      end
    end
  end
end
