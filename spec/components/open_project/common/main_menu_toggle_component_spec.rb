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

RSpec.describe OpenProject::Common::MainMenuToggleComponent, type: :component do
  let(:expanded) { true }

  subject do
    render_inline(described_class.new(expanded:)) do
      content
    end

    page
  end

  context "in expended state" do
    it "does render the expanded icon" do
      expect(subject).to have_element class: "octicon-sidebar-expand"
      expect(subject).to have_no_element class: "octicon-sidebar-collapse"
      expect(subject).to have_element id: "menu-toggle--collapse-button", aria: { expanded: true }
      expect(subject).to have_element "tool-tip",
                                      text: "Collapse project menu",
                                      for: "menu-toggle--collapse-button",
                                      popover: "manual",
                                      "data-type": "label"
    end
  end

  context "in collapsed state" do
    let(:expanded) { false }

    it "does render the collapsed icon" do
      expect(subject).to have_element class: "octicon-sidebar-collapse"
      expect(subject).to have_no_element class: "octicon-sidebar-expand"
      expect(subject).to have_element id: "menu-toggle--expand-button", aria: { expanded: false }
      expect(subject).to have_element "tool-tip",
                                      text: "Expand project menu",
                                      for: "menu-toggle--expand-button",
                                      popover: "manual",
                                      "data-type": "label"
    end
  end
end
