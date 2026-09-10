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
require Rails.root.join("modules/backlogs/db/migrate/20260825103847_backfill_sprint_started_and_completed_at")

RSpec.describe BackfillSprintStartedAndCompletedAt, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }

  let!(:in_planning) { create(:sprint, status: "in_planning") }

  let!(:active) do
    create(:sprint, status: "active", start_date: Date.new(2026, 1, 5), finish_date: Date.new(2026, 1, 20))
  end

  let!(:completed) do
    create(:sprint, status: "completed", start_date: Date.new(2026, 2, 1), finish_date: Date.new(2026, 2, 14))
  end

  let!(:active_without_dates) do
    build(:sprint, status: "active", start_date: nil, finish_date: nil).tap { |s| s.save!(validate: false) }
  end

  let!(:already_started) do
    create(:sprint, status: "active", start_date: Date.new(2026, 3, 1), finish_date: Date.new(2026, 3, 14)).tap do |s|
      s.update_column(:started_at, Time.zone.parse("2026-03-01 09:17:42 UTC"))
    end
  end

  let!(:already_started_and_completed) do
    create(:sprint, status: "completed", start_date: Date.new(2026, 4, 1), finish_date: Date.new(2026, 4, 14)).tap do |s|
      s.update_columns(
        started_at: Time.zone.parse("2026-04-01 09:17:42 UTC"),
        completed_at: Time.zone.parse("2026-04-14 16:03:11 UTC")
      )
    end
  end

  it "leaves sprints that are still in planning untouched" do
    migrate
    expect(in_planning.reload).to have_attributes(started_at: nil, completed_at: nil)
  end

  it "backfills started_at from start_date for active sprints" do
    migrate
    expect(active.reload.started_at).to eq(Time.zone.parse("2026-01-05 00:00:00 UTC"))
    expect(active.completed_at).to be_nil
  end

  it "backfills started_at from start_date and completed_at from finish_date for completed sprints" do
    migrate
    expect(completed.reload.started_at).to eq(Time.zone.parse("2026-02-01 00:00:00 UTC"))
    expect(completed.completed_at).to eq(Time.zone.parse("2026-02-14 00:00:00 UTC"))
  end

  it "does not fabricate a timestamp for legacy sprints with no start_date/finish_date" do
    migrate
    expect(active_without_dates.reload).to have_attributes(started_at: nil, completed_at: nil)
  end

  it "does not overwrite a started_at that was already set" do
    migrate
    expect(already_started.reload.started_at).to eq(Time.zone.parse("2026-03-01 09:17:42 UTC"))
  end

  it "does not overwrite a started_at and completed_at that were already set" do
    migrate
    expect(already_started_and_completed.reload).to have_attributes(
      started_at: Time.zone.parse("2026-04-01 09:17:42 UTC"),
      completed_at: Time.zone.parse("2026-04-14 16:03:11 UTC")
    )
  end
end
