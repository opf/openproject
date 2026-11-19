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

require "rails_helper"

RSpec.describe Backlogs::SprintReports::HeaderInfolineComponent, type: :component do
  let(:sprint) do
    build_stubbed(:sprint,
                  status: :active,
                  start_date: Date.new(2025, 1, 15),
                  finish_date: Date.new(2025, 1, 29))
  end

  subject(:rendered_component) { render_inline(described_class.new(sprint:)) }

  it "renders the sprint status" do
    expect(rendered_component).to have_text(I18n.t(:"activerecord.attributes.sprint.statuses.active"))
  end

  describe "dates" do
    let(:start_date) { Date.new(2025, 1, 15) }
    let(:finish_date) { Date.new(2025, 1, 29) }
    let(:started_at) { Time.utc(2025, 1, 16, 9, 30) }
    let(:completed_at) { Time.utc(2025, 1, 30, 17, 45) }

    current_user { build_stubbed(:user) }

    context "when the sprint is in planning" do
      let(:sprint) { build_stubbed(:sprint, status: :in_planning, start_date:, finish_date:) }

      it "shows the planned range without a time of day" do
        expect(rendered_component).to have_text("Planned:")
        expect(rendered_component).to have_element(:time, datetime: "2025-01-15")
        expect(rendered_component).to have_element(:time, datetime: "2025-01-29")
        expect(rendered_component).to have_element(:time, count: 2)
        expect(rendered_component).to have_no_text(/\d{2}:\d{2}/)
      end

      context "with only a start date" do
        let(:finish_date) { nil }

        it "shows the planned start as an open range" do
          expect(rendered_component).to have_text("Planned:")
          expect(rendered_component).to have_element(:time, datetime: "2025-01-15")
          expect(rendered_component).to have_element(:time, count: 1)
        end
      end

      context "with only a finish date" do
        let(:start_date) { nil }

        it "shows the planned finish as an open range" do
          expect(rendered_component).to have_text("Planned:")
          expect(rendered_component).to have_element(:time, datetime: "2025-01-29")
          expect(rendered_component).to have_element(:time, count: 1)
        end
      end

      context "without dates" do
        let(:start_date) { nil }
        let(:finish_date) { nil }

        it "shows no dates" do
          expect(rendered_component).to have_no_element(:time)
          expect(rendered_component).to have_no_text("Planned:")
        end
      end
    end

    context "when the sprint is active" do
      let(:sprint) { build_stubbed(:sprint, status: :active, start_date:, finish_date:, started_at:) }

      it "shows when it was started on its own, followed by the planned range" do
        expect(rendered_component).to have_element(:time, datetime: "2025-01-16T09:30:00Z", text: "09:30 AM")
        expect(rendered_component).to have_text(/09:30 AM\s+Planned:/)
        expect(rendered_component).to have_element(:time, datetime: "2025-01-15")
        expect(rendered_component).to have_element(:time, datetime: "2025-01-29")
      end

      context "without a start timestamp" do
        let(:started_at) { nil }

        it "shows only the planned range" do
          expect(rendered_component).to have_text("Planned:")
          expect(rendered_component).to have_element(:time, count: 2)
          expect(rendered_component).to have_no_text(/\d{2}:\d{2}/)
        end
      end
    end

    context "when the sprint is completed" do
      let(:sprint) do
        build_stubbed(:sprint, status: :completed, start_date:, finish_date:, started_at:, completed_at:)
      end

      it "shows when it was started and completed, followed by the planned range" do
        expect(rendered_component).to have_element(:time, datetime: "2025-01-16T09:30:00Z", text: "09:30 AM")
        expect(rendered_component).to have_element(:time, datetime: "2025-01-30T17:45:00Z", text: "05:45 PM")
        expect(rendered_component).to have_text("Planned:")
        expect(rendered_component).to have_element(:time, datetime: "2025-01-15")
        expect(rendered_component).to have_element(:time, datetime: "2025-01-29")
      end

      context "without planned dates" do
        let(:start_date) { nil }
        let(:finish_date) { nil }

        it "shows only when it was started and completed" do
          expect(rendered_component).to have_element(:time, count: 2)
          expect(rendered_component).to have_text("09:30 AM")
          expect(rendered_component).to have_text("05:45 PM")
          expect(rendered_component).to have_no_text("Planned:")
        end
      end
    end
  end
end
