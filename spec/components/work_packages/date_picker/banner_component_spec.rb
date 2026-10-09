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

RSpec.describe WorkPackages::DatePicker::BannerComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  create_shared_association_defaults_for_work_package_factory

  subject(:banner) do
    render_inline(described_class.new(work_package:, manually_scheduled:))
  end

  context "when manually scheduled" do
    let(:manually_scheduled) { true }

    context "without any predecessors or children" do
      let(:work_package) { build(:work_package) }

      it "displays banner 'Click on \"Show relations\" for Gantt overview.'" do
        expected_text = I18n.t("work_packages.datepicker_modal.banner.description.click_on_show_relations_to_open_gantt",
                               button_name: I18n.t("work_packages.datepicker_modal.show_relations"))
        expect(banner).to have_text(expected_text)
      end
    end

    context "with all predecessors leaving a gap between actual start date and soonest possible start date" do
      let_work_packages(<<~TABLE)
        hierarchy         | MTWTFSS | scheduling mode | predecessors
        pred_no_dates     |         | manual          |
        pred_dates        | XX      | manual          |
        work_package      |     X   | manual          | pred_dates, pred_no_dates with lag 2
      TABLE

      it "displays banner 'There is a gap between this and all predecessors.'" do
        expect(banner).to have_text(I18n.t("work_packages.datepicker_modal.banner.description.manual_gap_between_predecessors"))
      end
    end

    context "with some predecessors dates overlapping actual start date" do
      let_work_packages(<<~TABLE)
        hierarchy         | MTWTFSS | scheduling mode | predecessors
        pred_no_dates     |         | manual          |
        pred_dates        | XXXXX   | manual          |
        work_package      |   X     | manual          | pred_dates, pred_no_dates with lag 2
      TABLE

      it "displays banner 'There is a gap between this and all predecessors.'" do
        expect(banner).to have_text(I18n.t("work_packages.datepicker_modal.banner.description.manual_overlap_with_predecessors"))
      end
    end
  end
end
