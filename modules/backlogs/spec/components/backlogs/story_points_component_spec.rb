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

RSpec.describe Backlogs::StoryPointsComponent, type: :component do
  shared_let(:project) { create(:project) }

  it "renders the story points number visually" do
    work_package = create(:work_package, project:, story_points: 5)

    render_inline(described_class.new(work_package:))

    expect(page).to have_css("span", text: "5", aria: { hidden: true })
  end

  it "renders the story points label for screen readers" do
    work_package = create(:work_package, project:, story_points: 5)

    render_inline(described_class.new(work_package:))

    expect(page).to have_css(".sr-only", text: "5 story points")
  end

  it "positions the story points wrapper for the screen reader label" do
    work_package = create(:work_package, project:, story_points: 5)

    render_inline(described_class.new(work_package:))

    expect(page).to have_css(".position-relative .sr-only", text: "5 story points")
  end

  it "renders zero when story points are unset" do
    work_package = create(:work_package, project:, story_points: nil)

    render_inline(described_class.new(work_package:))

    expect(page).to have_css("span", text: "0", aria: { hidden: true })
    expect(page).to have_css(".sr-only", text: "0 story points")
  end
end
