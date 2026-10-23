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

RSpec.describe Labels::CleanupUnusedInlineJob, type: :job do
  let(:label) { create(:label, :created_inline, created_at: 2.days.ago, updated_at: 2.days.ago) }

  it "is scheduled nightly" do
    expect(Rails.application.config.good_job.cron[:"Labels::CleanupUnusedInlineJob"])
      .to include(cron: "37 2 * * *", class: described_class.name)
  end

  it "collapses repeated bookings into one pending run", with_good_job: described_class do
    2.times { described_class.perform_after_grace }

    expect(GoodJob::Job.where(concurrency_key: described_class.name).count).to eq(1)
  end

  describe ".perform_after_grace" do
    it "enqueues a run once the grace period has passed" do
      freeze_time

      expect { described_class.perform_after_grace }
        .to have_enqueued_job(described_class).at(described_class::GRACE_PERIOD.from_now)
    end
  end

  it "deletes an inline label older than the grace period that was never used" do
    label

    expect { described_class.perform_now }.to change(Label, :count).by(-1)
    expect(Label.exists?(label.id)).to be(false)
  end

  it "keeps an inline label younger than the grace period" do
    young = create(:label, :created_inline, created_at: 5.minutes.ago, updated_at: 5.minutes.ago)

    expect { described_class.perform_now }.not_to change(Label, :count)
    expect(Label.exists?(young.id)).to be(true)
  end

  it "keeps an inline label that was handed out again within the grace period" do
    recent = create(:label, :created_inline, created_at: 2.days.ago, updated_at: 5.minutes.ago)

    expect { described_class.perform_now }.not_to change(Label, :count)
    expect(Label.exists?(recent.id)).to be(true)
  end

  it "books the next run for when the oldest remaining inline label leaves its grace period" do
    freeze_time
    create(:label, :created_inline, updated_at: 5.minutes.ago)
    create(:label, :created_inline, updated_at: 10.minutes.ago)

    expect { described_class.perform_now }
      .to have_enqueued_job(described_class).at(5.minutes.from_now)
  end

  it "waits before retrying a label it could not lock" do
    freeze_time
    label
    job = described_class.new
    allow(job).to receive(:candidate_ids).and_return([])

    expect { job.perform_now }
      .to have_enqueued_job(described_class).at(described_class::MIN_WAIT.from_now)
  end

  it "books no further run when no unused inline label remains" do
    label

    expect { described_class.perform_now }.not_to have_enqueued_job(described_class)
  end

  it "keeps an admin-created label that was never used" do
    curated = create(:label, created_at: 2.days.ago, updated_at: 2.days.ago)

    expect { described_class.perform_now }.not_to change(Label, :count)
    expect(Label.exists?(curated.id)).to be(true)
  end

  it "keeps an inline label that only a journal snapshot references" do
    create(:journal_label_journal, journal: create(:work_package).journals.last, label:)

    expect { described_class.perform_now }.not_to change(Label, :count)
  end

  it "keeps a label that gets used between candidate selection and deletion" do
    label
    job = described_class.new
    allow(job).to receive(:candidate_ids).and_wrap_original do |original|
      original.call.tap { create(:labeling, label:) }
    end

    expect { job.perform_now }.not_to change(Label, :count)
    expect(Labeling.where(label:)).to exist
  end

  describe "labels added to and removed from a work package" do
    shared_let(:user) { create(:admin) }
    shared_let(:work_package) do
      create(:work_package, journals: { 10.minutes.ago => { user: } })
    end

    current_user { user }

    def set_labels(label_ids)
      WorkPackages::UpdateService.new(user:, model: work_package).call(label_ids:)
    end

    context "when both changes happen within the journal aggregation time",
            with_settings: { journal_aggregation_time_minutes: 5 } do
      it "leaves no journal snapshot behind and the label is deleted" do
        set_labels([label.id])
        set_labels([])

        expect(Journal::LabelJournal.where(label:)).to be_empty
        expect { described_class.perform_now }.to change(Label, :count).by(-1)
      end
    end

    context "when the removal happens after the journal aggregation time",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      it "keeps the label because an earlier journal still references it" do
        set_labels([label.id])
        set_labels([])

        expect(Journal::LabelJournal.where(label:)).to exist
        expect { described_class.perform_now }.not_to change(Label, :count)
      end
    end
  end
end
