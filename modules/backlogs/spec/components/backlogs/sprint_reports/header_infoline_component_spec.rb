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

  context "when the sprint has a date range" do
    it "shows the start and finish dates" do
      expect(rendered_component).to have_css("time[datetime='2025-01-15']")
      expect(rendered_component).to have_css("time[datetime='2025-01-29']")
    end
  end

  context "when the sprint has no date range" do
    let(:sprint) { build_stubbed(:sprint, start_date: nil, finish_date: nil) }

    it "does not show dates" do
      expect(rendered_component).to have_no_css("time")
    end
  end
end
