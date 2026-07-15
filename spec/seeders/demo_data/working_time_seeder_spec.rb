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

RSpec.describe DemoData::WorkingTimeSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new({}) }

  let(:marko) { create(:user) }  # single full-time schedule + vacation
  let(:dora) { create(:user) }   # schedule change over the summer
  let(:olga) { create(:user) }   # schedule change (four-day week)
  let(:fritz) { create(:user) }  # part-time, very low hours
  let(:connie) { create(:user) } # no schedule
  let(:polly) { create(:user) }  # no schedule, but a vacation

  before do
    seed_data.store_reference(:user__marko_marketing, marko)
    seed_data.store_reference(:user__dora_design, dora)
    seed_data.store_reference(:user__olga_ops, olga)
    seed_data.store_reference(:user__fritz_finance, fritz)
    seed_data.store_reference(:user__connie_comms, connie)
    seed_data.store_reference(:user__polly_pr, polly)

    seeder.seed!
  end

  it "creates a single full-time schedule for a user with one schedule" do
    expect(marko.working_hours.count).to eq 1
    expect(marko.working_hours.sole.weekly_working_hours).to eq 40
  end

  it "creates multiple dated schedules for a user whose schedule changes" do
    schedules = dora.working_hours.order(:valid_from).to_a
    expect(schedules.count).to eq 3

    # full-time, then half days over the summer, then full-time again
    expect(schedules.map(&:weekly_working_hours)).to eq [40, 20, 40]
    expect(schedules.map(&:valid_from).uniq.count).to eq 3

    expect(olga.working_hours.count).to eq 2
  end

  it "gives Fritz Finance a part-time schedule with very low hours" do
    schedule = fritz.working_hours.sole
    expect(schedule.weekly_working_hours).to eq 6
  end

  it "leaves users without a schedule untouched" do
    expect(connie.working_hours).to be_empty
    expect(polly.working_hours).to be_empty
  end

  it "creates vacations, including for a user without a schedule" do
    expect(marko.non_working_times.count).to eq 1
    expect(polly.non_working_times.count).to eq 1
  end

  it "is not applicable once working times exist" do
    expect(seeder).not_to be_applicable
  end
end
