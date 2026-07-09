# frozen_string_literal: true

# -- copyright
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
# ++

require "rails_helper"

RSpec.describe Users::UserGroupFilterComponent, type: :component do
  let(:group1) { build_stubbed(:group, lastname: "Developers") }
  let(:group2) { build_stubbed(:group, lastname: "Designers") }
  let(:query) { UserQuery.new }

  subject(:component) { described_class.new(query:) }

  before do
    allow(Group).to receive(:order).with(:lastname).and_return([group2, group1])

    render_inline(component)
  end

  it "renders the available groups" do
    expect(page).to have_text(group1.name)
    expect(page).to have_text(group2.name)
  end

  context "when groups are selected" do
    let(:query) { UserQuery.new.where(:group, "=", [group1.id.to_s, group2.id.to_s]) }

    it "marks all selected groups as selected" do
      expect(page).to have_css("[aria-selected='true']", text: group1.name, visible: :all)
      expect(page).to have_css("[aria-selected='true']", text: group2.name, visible: :all)
    end

    it "shows the number of selected groups on the button" do
      expect(page).to have_css("button .Counter", text: "2")
    end
  end

  context "when no group is selected" do
    it "does not mark any group as selected" do
      expect(page).to have_no_css("[aria-selected='true']", visible: :all)
    end
  end
end
