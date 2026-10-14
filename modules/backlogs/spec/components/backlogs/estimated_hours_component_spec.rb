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

RSpec.describe Backlogs::EstimatedHoursComponent, type: :component do
  shared_let(:project) { create(:project) }

  it "renders the formatted estimated hours visually" do
    work_package = create(:work_package, project:, estimated_hours: 8)

    render_inline(described_class.new(work_package:))

    expect(page).to have_css("span", text: DurationConverter.output(8), aria: { hidden: true })
  end

  it "renders the estimated hours label for screen readers" do
    work_package = create(:work_package, project:, estimated_hours: 8)

    render_inline(described_class.new(work_package:))

    label = "#{DurationConverter.output(8)} #{WorkPackage.human_attribute_name(:estimated_hours)}"
    expect(page).to have_css(".sr-only", text: label)
  end

  it "positions the estimated hours wrapper for the screen reader label" do
    work_package = create(:work_package, project:, estimated_hours: 8)

    render_inline(described_class.new(work_package:))

    expect(page).to have_css(".position-relative .sr-only", text: WorkPackage.human_attribute_name(:estimated_hours))
  end
end
