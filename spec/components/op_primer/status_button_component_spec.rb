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

RSpec.describe OpPrimer::StatusButtonComponent, type: :component do
  let(:current_status) do
    OpPrimer::StatusButtonOption.new(
      name: "In Progress",
      icon: "clock",
      color: nil
    )
  end

  let(:items) { [] }
  let(:readonly) { false }
  let(:title) { "foo" }

  subject(:component) do
    described_class.new(
      current_status:,
      items:,
      readonly:,
      button_arguments: { title: }.compact
    )
  end

  context "when rendering with an icon status" do
    it "renders the status with an icon" do
      render_inline(component)

      expect(page).to have_css(".octicon-clock")
      expect(page).to have_text("In Progress")
    end
  end

  context "when rendering with items" do
    let(:items) do
      [
        OpPrimer::StatusButtonOption.new(name: "Todo", icon: "circle", color: nil),
        OpPrimer::StatusButtonOption.new(name: "Done", icon: "check", color: nil)
      ]
    end

    it "renders a dropdown button" do
      render_inline(component)

      expect(page).to have_css(".octicon-triangle-down")
    end

    it "renders menu items with icons" do
      render_inline(component)

      expect(page).to have_css(".octicon-circle")
      expect(page).to have_css(".octicon-check")
      expect(page).to have_text("Todo")
      expect(page).to have_text("Done")
    end
  end

  context "when readonly" do
    let(:readonly) { true }

    it "does not render the dropdown or icon" do
      render_inline(component)

      expect(page).to have_no_css(".octicon-triangle-down")
      expect(page).to have_no_css(".ActionMenu")
    end
  end

  context "when title not provided" do
    let(:title) { nil }

    it "raises an exception" do
      expect { render_inline(component) }.to raise_error(SubclassResponsibilityError)
    end
  end
end
