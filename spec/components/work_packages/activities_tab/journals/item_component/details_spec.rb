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

require "spec_helper"

RSpec.describe WorkPackages::ActivitiesTab::Journals::ItemComponent::Details, type: :component do
  shared_let(:user) { create(:user) }
  shared_let(:work_package) { create(:work_package) }

  let(:journal) { build_stubbed(:work_package_journal, journable: work_package, user:, version: 2) }

  subject(:component) do
    described_class.new(journal:, filter: WorkPackages::ActivitiesTab::Filters::ALL)
  end

  before do
    login_as(user)

    allow(journal).to receive(:details).and_return(details)
    rendered.each { |detail, text| allow(journal).to receive(:render_detail).with(detail).and_return(text) }

    render_inline(component)
  end

  context "with a detail that renders" do
    let(:details) { { "subject" => ["Old", "New"] } }
    let(:rendered) { { ["subject", ["Old", "New"]] => "Subject changed from Old to New" } }

    it "renders the change" do
      expect(page).to have_text("Subject changed from Old to New")
    end

    it "heads the change with its author and time" do
      expect(page).to have_css("[data-test-selector='op-journal-details-header']")
    end
  end

  # A formatter that renders nothing leaves the entry with no change to show, so
  # a header would announce an author and a time above an empty entry.
  context "when every detail renders blank" do
    let(:details) { { "type_id" => [1, 2] } }
    let(:rendered) { { ["type_id", [1, 2]] => nil } }

    it "renders no header" do
      expect(page).to have_no_css("[data-test-selector='op-journal-details-header']")
    end

    it "renders no change" do
      expect(page).to have_no_css("[data-test-selector='op-journal-detail-description']")
    end
  end
end
