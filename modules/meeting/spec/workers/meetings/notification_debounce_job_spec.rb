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

RSpec.describe Meetings::NotificationDebounceJob do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] }) }
  shared_let(:meeting) { create(:meeting, project:, author: user, notify: true) }

  let(:dispatch_service) { instance_double(Meetings::DispatchAggregatedNotificationsService) }

  before do
    allow(Meetings::DispatchAggregatedNotificationsService)
      .to receive(:new)
            .and_return(dispatch_service)
    allow(dispatch_service).to receive(:call)
  end

  describe ".debounce" do
    it "enqueues a background job" do
      expect { described_class.debounce(meeting) }
        .to have_enqueued_job(described_class)
              .with(meeting.id, anything, anything, anything)
    end

    it "does not call the dispatch service synchronously" do
      described_class.debounce(meeting)
      expect(dispatch_service).not_to have_received(:call)
    end

    context "when querying GoodJob directly",
            with_good_job: described_class do
      it "writes the job to the GoodJob::Job table with the correct concurrency key" do
        described_class.debounce(meeting)

        job = GoodJob::Job.where(concurrency_key: described_class.unique_key_for(meeting.id)).first
        expect(job).not_to be_nil
        expect(job.serialized_params.dig("arguments", 0)).to eq(meeting.id)
      end

      it "passes nil since_journal_id when meeting journal has no predecessor" do
        described_class.debounce(meeting)

        job = GoodJob::Job.where(concurrency_key: described_class.unique_key_for(meeting.id)).first
        expect(job.serialized_params.dig("arguments", 1)).to be_nil
      end

      context "when called multiple times (debounce reset)" do
        before { described_class.debounce(meeting) }

        it "leaves only one pending job" do
          described_class.debounce(meeting)

          count = GoodJob::Job.where(finished_at: nil, concurrency_key: described_class.unique_key_for(meeting.id)).count
          expect(count).to eq(1)
        end

        it "preserves the since_journal_id from the first call" do
          first_since_id = GoodJob::Job.where(concurrency_key: described_class.unique_key_for(meeting.id))
                                       .first
                                       .serialized_params
                                       .dig("arguments", 1)

          described_class.debounce(meeting)

          job = GoodJob::Job.where(finished_at: nil, concurrency_key: described_class.unique_key_for(meeting.id)).first
          expect(job.serialized_params.dig("arguments", 1)).to eq(first_since_id)
        end

        it "preserves explicit since_attributes from the first call" do
          described_class.debounce(meeting, since_attributes: { "title" => "Initial title" })
          described_class.debounce(meeting, since_attributes: { "title" => "Later title" })

          job = GoodJob::Job.where(finished_at: nil, concurrency_key: described_class.unique_key_for(meeting.id)).first
          expect(job.serialized_params.dig("arguments", 3, "title")).to eq("Initial title")
        end
      end
    end
  end

  describe ".cancel_pending", with_good_job: described_class do
    before do
      described_class.debounce(meeting)
    end

    it "removes pending jobs for the meeting" do
      expect do
        described_class.cancel_pending(meeting)
      end.to change {
        GoodJob::Job.where(finished_at: nil, concurrency_key: described_class.unique_key_for(meeting.id)).count
      }.from(1).to(0)
    end
  end

  describe "#perform" do
    let(:since_journal) { meeting.last_journal }
    let(:latest_journal) { instance_double(Journal, id: since_journal.id + 1, user: user) }

    before do
      allow(meeting.class).to receive(:find_by).with(id: meeting.id).and_return(meeting)
      allow(Journal).to receive(:find_by).with(id: since_journal.id).and_return(since_journal)
      allow(meeting).to receive(:last_journal).and_return(latest_journal)
    end

    subject { described_class.new.perform(meeting.id, since_journal.id) }

    it "calls the dispatch service with the correct journals" do
      subject
      expect(Meetings::DispatchAggregatedNotificationsService)
        .to have_received(:new)
              .with(meeting:,
                    since_journal:,
                    latest_journal:,
                    since_invited_ids: nil,
                    since_attributes: nil)
      expect(dispatch_service).to have_received(:call)
    end

    context "when meeting does not exist" do
      before { allow(meeting.class).to receive(:find_by).with(id: meeting.id).and_return(nil) }

      it "does nothing" do
        subject
        expect(dispatch_service).not_to have_received(:call)
      end
    end

    context "when meeting cannot send emails" do
      before { allow(meeting).to receive(:send_emails?).and_return(false) }

      it "does nothing" do
        subject
        expect(dispatch_service).not_to have_received(:call)
      end
    end

    context "when latest journal equals since_journal_id (no change)" do
      before { allow(meeting).to receive(:last_journal).and_return(since_journal) }

      it "does nothing" do
        subject
        expect(dispatch_service).not_to have_received(:call)
      end
    end

    context "when there is no latest journal" do
      before { allow(meeting).to receive(:last_journal).and_return(nil) }

      it "does nothing" do
        subject
        expect(dispatch_service).not_to have_received(:call)
      end
    end
  end
end
