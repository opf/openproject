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

require "rails_helper"

RSpec.describe Users::WorkingHours::DaysAndHoursForm do
  # The form is built by Primer with a form builder it has no use for here, and the order
  # of the days depends on nothing but the setting.
  subject(:ordered_days) { described_class.allocate.send(:ordered_days) }

  context "when the week starts on Monday", with_settings: { start_of_week: 1 } do
    it { is_expected.to eq(%i[monday tuesday wednesday thursday friday saturday sunday]) }
  end

  context "when the week starts on Sunday", with_settings: { start_of_week: 7 } do
    it { is_expected.to eq(%i[sunday monday tuesday wednesday thursday friday saturday]) }
  end

  context "when the week starts on Saturday", with_settings: { start_of_week: 6 } do
    it { is_expected.to eq(%i[saturday sunday monday tuesday wednesday thursday friday]) }
  end

  # The form used to fall back to Monday of its own accord, which listed the days in a
  # different order than the calendars derive their week from the language.
  context "when no start of week is set", with_settings: { start_of_week: nil } do
    context "and the language starts the week on Sunday" do
      before { allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("7") }

      it { is_expected.to start_with(:sunday) }
    end

    context "and the language starts the week on Monday" do
      before { allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("1") }

      it { is_expected.to start_with(:monday) }
    end
  end

  it "keeps every day exactly once", with_settings: { start_of_week: 6 } do
    expect(ordered_days).to match_array(UserWorkingHours::DAYS)
  end
end
