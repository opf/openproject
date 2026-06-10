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

RSpec.describe OpPrimer::QuickFilter::BooleanComponent, type: :component do
  include QuickFilterHelpers

  let(:project) { build_stubbed(:project) }
  let(:query) { build_meeting_query }

  subject(:component) do
    described_class.new(
      name: "Boolean filter",
      query:,
      filter_key: :type,
      true_label: "Yes",
      false_label: "No",
      path_args: [project, :meetings]
    )
  end

  context "when rendering" do
    before { render_inline(component) }

    it "renders both items with the provided labels" do
      expect(page).to have_text("Yes")
      expect(page).to have_text("No")
    end

    it "renders exactly two items" do
      expect(page).to have_css("a", count: 2)
    end

    it "uses 't' and 'f' as filter values" do
      expect(filters_from_link(page.find("a", text: "Yes")))
        .to include({ "type" => { "operator" => "=", "values" => ["t"] } })
      expect(filters_from_link(page.find("a", text: "No")))
        .to include({ "type" => { "operator" => "=", "values" => ["f"] } })
    end
  end

  context "when the true value is active" do
    let(:query) { build_meeting_query.where("type", "=", ["t"]) }

    before do
      render_inline(component)
    end

    it "marks the true item as selected" do
      expect(page).to have_css("[aria-current='true']", text: "Yes")
    end

    it "does not mark the false item as selected" do
      expect(page).to have_no_css("[aria-current='true']", text: "No")
    end
  end
end
