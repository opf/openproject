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

RSpec.describe Statuses::ListHeaderComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new) }

  def captioned_areas
    rendered_component.css("[class*='op-statuses-list--header--']").map do |cell|
      cell["class"][/op-statuses-list--header--(\S+)/, 1]
    end
  end

  context "in status-based progress mode", with_settings: { work_package_done_ratio: "status" } do
    it "captions each column in the order the grid lays them out" do
      expect(captioned_areas).to eq(%w[name done-ratio is-default is-closed is-readonly])
    end

    it "names the columns", :aggregate_failures do
      expect(rendered_component).to have_text(Status.human_attribute_name(:name))
      expect(rendered_component).to have_text(WorkPackage.human_attribute_name(:done_ratio))
      expect(rendered_component).to have_text("Default")
      expect(rendered_component).to have_text("Closed")
      expect(rendered_component).to have_text("Read-only")
    end

    it "keeps the full grid" do
      expect(rendered_component).to have_no_css(".op-statuses-list--header_without-done-ratio")
    end
  end

  context "in work-based progress mode", with_settings: { work_package_done_ratio: "field" } do
    it "drops the % Complete column, which has no effect in that mode" do
      expect(captioned_areas).to eq(%w[name is-default is-closed is-readonly])
    end

    # Rows carry the matching modifier: the two grids only stay aligned while both
    # drop the same column.
    it "narrows the grid" do
      expect(rendered_component).to have_css(".op-statuses-list--header_without-done-ratio")
    end
  end
end
