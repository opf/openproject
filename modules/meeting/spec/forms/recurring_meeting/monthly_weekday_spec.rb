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

RSpec.describe RecurringMeeting::MonthlyWeekday, type: :forms do
  include ViewComponent::TestHelpers

  def render_form
    render_in_view_context(described_class) do |described_class|
      primer_form_with(url: "/foo", scope: :meeting) do |f|
        render(described_class.new(f))
      end
    end
  end

  def option_values
    page
      .all("select[name='meeting[monthly_weekday]'] option")
      .map { |option| option[:value] }
  end

  context "with start_of_week on monday", with_settings: { start_of_week: 1 } do
    it "orders weekdays from monday to sunday" do
      render_form

      expect(option_values).to eq(%w[monday tuesday wednesday thursday friday saturday sunday])
    end
  end

  context "with start_of_week on sunday", with_settings: { start_of_week: 7 } do
    it "orders weekdays from sunday to saturday" do
      render_form

      expect(option_values).to eq(%w[sunday monday tuesday wednesday thursday friday saturday])
    end
  end

  context "when week start is based on locale", with_settings: { start_of_week: nil } do
    it "uses monday-first for german" do
      I18n.with_locale(:de) do
        render_form
      end

      expect(option_values).to eq(%w[monday tuesday wednesday thursday friday saturday sunday])
    end

    it "uses sunday-first for english" do
      I18n.with_locale(:en) do
        render_form
      end

      expect(option_values).to eq(%w[sunday monday tuesday wednesday thursday friday saturday])
    end
  end
end
