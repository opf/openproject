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

RSpec.describe WorkPackages::Reminder::ModalBodyComponent, type: :component do
  let(:remindable) { build_stubbed(:work_package) }
  let(:reminder) { build_stubbed(:reminder) }
  let(:preset) { nil }

  subject(:component) { described_class.new(remindable:, reminder:, preset:) }

  before do
    render_inline(component)
  end

  context "when the reminder is persisted" do
    it "renders the component with the reminder data" do
      expect(page).to have_field("Date", with: reminder.remind_at.in_time_zone(User.current.time_zone).to_date)
      expect(page).to have_field("Time", with: reminder.remind_at.in_time_zone(User.current.time_zone).strftime("%H:%M"))
      expect(page).to have_field("Note", with: reminder.note)

      expect(page).to have_button("Save")
    end
  end

  context "when the reminder is not persisted" do
    let(:reminder) { Reminder.new }

    it "renders the component with the default data" do
      expect(page).to have_field("Date")
      expect(page.find_field("Date").value).to be_nil

      expect(page).to have_field("Time", with: "09:00")
      expect(page).to have_field("Note")

      expect(page).to have_button("Set reminder")
    end
  end

  describe "Date presets" do
    let(:reminder) { Reminder.new }

    shared_examples "Date field with preset value" do |preset_key, preset_value|
      context "when the preset is #{preset_key}" do
        let(:preset) { preset_key }

        it "renders the Date field with value #{preset_key}: #{preset_value.to_date}" do
          expect(page).to have_field("Date", with: preset_value.to_date)
        end
      end
    end

    it_behaves_like "Date field with preset value", "tomorrow", 1.day.from_now
    it_behaves_like "Date field with preset value", "three_days", 3.days.from_now
    it_behaves_like "Date field with preset value", "week", 7.days.from_now
    it_behaves_like "Date field with preset value", "month", 1.month.from_now

    context "when the preset is custom" do
      let(:preset) { "custom" }

      it "renders the Date field without a value" do
        date_field = page.find_field("Date")
        expect(date_field.value).to be_nil
      end
    end
  end
end
