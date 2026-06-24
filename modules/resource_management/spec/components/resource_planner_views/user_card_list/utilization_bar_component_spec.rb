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

RSpec.describe ResourcePlannerViews::UserCardList::UtilizationBarComponent, type: :component do
  def bar(value) = described_class.new(value:)

  it "renders nothing without a value" do
    render_inline(bar(nil))

    expect(page).to have_no_test_selector("utilization-bar")
  end

  describe "the bar colour and width by utilization" do
    it "is accent and proportional below 100%" do
      expect(bar(34).send(:bar_color)).to eq(:accent_emphasis)
      expect(bar(34).send(:bar_percentage)).to eq(34)
    end

    it "is success exactly at 100%" do
      expect(bar(100).send(:bar_color)).to eq(:success_emphasis)
    end

    it "is danger and capped at 100% above full, while the label keeps the real ratio" do
      expect(bar(150).send(:bar_color)).to eq(:danger_emphasis)
      expect(bar(150).send(:bar_percentage)).to eq(100)

      render_inline(bar(150))
      expect(page).to have_css("[data-test-selector='utilization-bar'][aria-label='150%']")
    end
  end
end
