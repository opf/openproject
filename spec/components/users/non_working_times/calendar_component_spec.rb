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

RSpec.describe Users::NonWorkingTimes::CalendarComponent, type: :component do
  let(:user) { create(:user) }

  subject(:start_of_week) do
    render_inline(described_class.new(user:))

    page.find("[data-controller='users--non-working-times']")["data-users--non-working-times-start-of-week-value"]
  end

  before do
    login_as user
  end

  context "when the week starts on Monday", with_settings: { start_of_week: 1 } do
    it { is_expected.to eq("1") }
  end

  context "when the week starts on Sunday", with_settings: { start_of_week: 7 } do
    it { is_expected.to eq("0") }
  end

  context "when the week starts on Saturday", with_settings: { start_of_week: 6 } do
    it { is_expected.to eq("6") }
  end

  # The component used to fall back to Monday of its own accord, which put the calendar out
  # of step with everything deriving its week from the language.
  context "when no start of week is set", with_settings: { start_of_week: nil } do
    context "and the language starts the week on Sunday" do
      before { allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("7") }

      it { is_expected.to eq("0") }
    end

    context "and the language starts the week on Monday" do
      before { allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("1") }

      it { is_expected.to eq("1") }
    end
  end
end
