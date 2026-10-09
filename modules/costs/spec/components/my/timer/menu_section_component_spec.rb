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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe My::Timer::MenuSectionComponent, type: :component do
  let(:work_package) { build_stubbed(:work_package, subject: "Plan the conference") }
  let(:created_at) { Time.zone.parse("2026-10-09T10:00:00Z") }
  let(:time_entry) { build_stubbed(:time_entry, entity: work_package, ongoing: true, hours: nil, created_at:) }

  subject(:rendered_component) { render_inline(described_class.new(time_entry:)) }

  context "without a running timer" do
    let(:time_entry) { nil }

    it "renders nothing" do
      expect(rendered_component.to_html).to be_blank
    end
  end

  context "with a running timer" do
    it "exposes the timer state for the avatar badge" do
      payload = JSON.parse(rendered_component.at_css("[data-ongoing-timer]")["data-ongoing-timer"])

      expect(payload).to eq(
        "id" => time_entry.id.to_s,
        "createdAt" => created_at.iso8601,
        "entityId" => work_package.id.to_s,
        "entityName" => "#{work_package.formatted_id}: Plan the conference"
      )
    end

    it "ticks the elapsed time from the timer start" do
      expect(rendered_component).to have_css(
        "[data-controller='my--timers'][data-my--timers-start-value='#{created_at.iso8601}']"
      )
    end

    it "links to the work package" do
      expect(rendered_component).to have_link("#{work_package.formatted_id}: Plan the conference",
                                              href: "/work_packages/#{work_package.id}")
    end

    it "stops the timer through the time entry dialog" do
      expect(rendered_component).to have_css(
        "[data-test-selector='op-timer-account-menu-stop'][data-turbo-stream]" \
        "[href='/time_entries/#{time_entry.id}/dialog?onlyMe=true']"
      )
    end
  end
end
