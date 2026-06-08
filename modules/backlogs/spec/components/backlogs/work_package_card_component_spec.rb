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

RSpec.describe Backlogs::WorkPackageCardComponent, type: :component do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:project) { create(:project, types: [type_feature]) }

  let(:menu_src) { "/backlogs/work_packages/#{work_package.id}/menu" }
  let(:work_package) do
    create(:work_package,
           project:,
           type: type_feature,
           story_points: 5,
           subject: "Backlogs card")
  end

  subject(:rendered_component) do
    render_inline(described_class.new(work_package:, menu_src:))
  end

  it "renders the common work package card" do
    expect(rendered_component).to have_text("Backlogs card")
    expect(rendered_component).to have_text("##{work_package.id}")
  end

  it "renders story points as the card metric" do
    expect(rendered_component).to have_css("span", text: "5", aria: { hidden: true })
    expect(rendered_component).to have_css(".sr-only", text: "5 story points")
  end

  it "supports caller-provided metric content" do
    rendered = render_inline(described_class.new(work_package:, menu_src:)) do |card|
      card.with_metric { "Custom metric" }
    end

    expect(rendered).to have_text("Custom metric")
    expect(rendered).to have_no_css(".sr-only", text: "5 story points")
  end

  it "passes the menu source to the common card" do
    expect(rendered_component).to have_element "include-fragment",
                                               src: menu_src
  end

  it "forwards extra system arguments to the common card root" do
    rendered = render_inline(described_class.new(work_package:, menu_src:, data: { controller: "backlogs--story" }))

    expect(rendered).to have_css("article[data-controller='backlogs--story']")
  end

  it "supports inline menu items through the menu slot" do
    rendered = render_inline(described_class.new(work_package:, menu_src:)) do |card|
      card.with_menu(button_aria_label: "Backlogs card actions") do |menu|
        menu.with_item(label: "Open", href: "/work_packages/#{work_package.id}")
      end
    end

    expect(rendered).to have_link "Open", href: "/work_packages/#{work_package.id}"
    expect(rendered).to have_button(
      "work_package_#{work_package.id}_menu-button",
      accessible_name: "Backlogs card actions"
    )
    expect(rendered).to have_no_element "include-fragment"
    expect(rendered).to have_css("span", text: "5", aria: { hidden: true })
    expect(rendered).to have_css(".sr-only", text: "5 story points")
  end
end
