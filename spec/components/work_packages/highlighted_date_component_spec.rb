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

RSpec.describe WorkPackages::HighlightedDateComponent, type: :component do
  let(:user) { build_stubbed(:user, preferences:) }
  let(:preferences) { {} }
  let(:work_package) { build_stubbed(:work_package, start_date:, due_date:) }
  let(:start_date) { Date.new(2026, 10, 11) }
  let(:due_date) { Date.new(2026, 10, 12) }

  before do
    login_as(user)

    render_inline(described_class.new(work_package:))
  end

  context "when user has date format preference" do
    let(:preferences) { { "date_format" => "%d.%m.%Y" } }

    it "renders both dates in the preferred format" do
      expect(page).to have_text("11.10.2026")
      expect(page).to have_text("12.10.2026")
    end
  end

  context "with a global setting", with_settings: { date_format: "%Y/%m/%d" } do
    it "renders both dates with that format" do
      expect(page).to have_text("2026/10/11")
      expect(page).to have_text("2026/10/12")
    end
  end

  context "without global setting" do
    it "renders both dates with incomprehensible format" do
      expect(page).to have_text("10/11/2026")
      expect(page).to have_text("10/12/2026")
    end
  end
end
