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

RSpec.describe My::Work::ListStatsComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:date) { Date.civil(2022, 5, 4) }

  subject(:rendered_component) do
    render_component(time_entries:, date:)
  end

  shared_examples_for "applying an ID" do
    it "applies an ID" do
      expect(rendered_component).to have_element id: "time-entries-list-stats-2022-05-04"
    end
  end

  context "with no time entries" do
    let(:time_entries) { build_list(:time_entry, 0) }

    include_examples "applying an ID"

    it "renders count" do
      expect(rendered_component).to have_primer_text "0 Time entries", color: "muted"
    end

    it "renders sum" do
      expect(rendered_component).to have_text "0h"
    end
  end

  context "with time entries" do
    let(:time_entries) { build_list(:time_entry, 2, hours: 1.325) }

    include_examples "applying an ID"

    it "renders count" do
      expect(rendered_component).to have_primer_text "2 Time entries", color: "muted"
    end

    it "renders sum" do
      expect(rendered_component).to have_text "2h 39m"
    end
  end
end
