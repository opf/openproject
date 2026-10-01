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

RSpec.describe RecurringMeetings::TableComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:recurring_meeting) { create(:recurring_meeting) }
  let(:meetings) do
    Array.new(count) do |i|
      create(:meeting,
             recurring_meeting:,
             recurrence_start_time: (i + 1).days.from_now,
             start_time: (i + 1).days.from_now)
    end
  end

  let(:current_project) { nil }
  let(:direction) { "upcoming" }
  let(:max_count) { 50 }

  subject(:rendered_component) do
    render_component(recurring_meeting:, rows: meetings, current_project:, count:, direction:, max_count:)
  end

  shared_examples_for "rendering Border Box Grid headings" do
    include_examples "rendering Border Box Grid heading", text: "Date and time"
    include_examples "rendering Border Box Grid heading", text: "Starts"
    include_examples "rendering Border Box Grid heading", text: "Status"
    include_examples "rendering Border Box Grid mobile heading", text: "Recurring meetings"
  end

  context "with no recurring meetings" do
    let(:count) { 0 }

    it_behaves_like "rendering Box", row_count: 1, footer: true
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Blank Slate", heading: "Nothing to display"
  end

  context "with recurring meetings" do
    let(:count) { 2 }

    it_behaves_like "rendering Box", row_count: 2, footer: true
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 2, col_count: 4
  end
end
