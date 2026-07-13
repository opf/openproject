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

RSpec.describe OpenProject::Common::WorkPackageCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }

  shared_let(:project) { create(:project, types: [type_feature]) }

  let(:menu_src) { "/work_packages/#{work_package.id}/menu" }
  let(:parent) { nil }
  let(:work_package) do
    create(:work_package,
           project:,
           type: type_feature,
           status: default_status,
           priority: default_priority,
           subject: "Card subject",
           story_points: 5,
           position: 1,
           sprint: nil,
           parent:)
  end

  let(:component) do
    described_class.new(work_package:, menu_src:)
  end
  let(:menu_button_id) { "work_package_#{work_package.id}_menu-button" }

  subject(:rendered_component) do
    render_inline(component)
  end

  it "renders the work-package info line (type + id)" do
    expect(rendered_component).to have_text("FEATURE")
    expect(rendered_component).to have_text("##{work_package.id}")
  end

  it "renders the subject in semibold text" do
    expect(rendered_component).to have_text("Card subject")
  end

  it "does not render story points by default" do
    expect(rendered_component).to have_no_text("5 points", normalize_ws: true)
  end

  it "renders the metric slot when provided" do
    rendered = render_inline(component) do |card|
      card.with_metric { "Custom metric" }
    end

    expect(rendered).to have_text("Custom metric")
  end

  it "renders a WorkPackageCardComponent::Menu kebab" do
    expect(rendered_component).to have_element :"action-menu"
    expect(rendered_component).to have_button(menu_button_id)
  end

  it "uses the work package actions label" do
    expect(rendered_component).to have_button(
      menu_button_id,
      accessible_name: I18n.t("open_project.common.work_package_card_component.menu.label_actions")
    )
  end

  it "uses the provided menu src" do
    expect(rendered_component).to have_element "include-fragment", src: menu_src
  end

  it "supports inline menu items through the menu slot" do
    rendered = render_inline(component) do |card|
      card.with_menu(button_aria_label: "Card actions") do |menu|
        menu.with_item(label: "Open", href: "/work_packages/#{work_package.id}")
      end
    end

    expect(rendered).to have_link "Open", href: "/work_packages/#{work_package.id}"
    expect(rendered).to have_button(menu_button_id, accessible_name: "Card actions")
    expect(rendered).to have_no_element "include-fragment"
  end

  it "supports deferred menu loading through the menu slot" do
    rendered = render_inline(described_class.new(work_package:)) do |card|
      card.with_menu(src: menu_src)
    end

    expect(rendered).to have_element "include-fragment", src: menu_src
  end

  it "uses the menu slot before the initializer menu source" do
    rendered = render_inline(component) do |card|
      card.with_menu(src: "/slot-menu")
    end

    expect(rendered).to have_element "include-fragment", src: "/slot-menu"
    expect(rendered).to have_no_element "include-fragment", src: menu_src
  end

  describe "parent display" do
    context "when show_parent is false (default)" do
      let(:parent) { create(:work_package, project:) }

      it "does not render the parent row" do
        expect(rendered_component).to have_no_text("Parent")
      end
    end

    context "when show_parent is true" do
      let(:component) { described_class.new(work_package:, menu_src:, show_parent: true) }

      context "when the work package has no parent" do
        let(:parent) { nil }

        it "does not render the parent row" do
          expect(rendered_component).to have_no_text("Parent")
        end
      end

      context "when the work package has a visible parent" do
        let(:parent) { create(:work_package, project:, subject: "Parent subject") }

        before { allow(work_package.parent).to receive(:visible?).and_return(true) }

        it "renders a link to the parent" do
          expect(rendered_component).to have_text("Parent")
          expect(rendered_component).to have_link("Parent subject", href: work_package_path(parent))
        end

        it "does not render Undisclosed" do
          expect(rendered_component).to have_no_text("Undisclosed")
        end
      end

      context "when the work package has a non-visible parent" do
        let(:parent) { create(:work_package, project:, subject: "Hidden subject") }

        before { allow(work_package.parent).to receive(:visible?).and_return(false) }

        it "renders Undisclosed instead of a link" do
          expect(rendered_component).to have_text("Parent")
          expect(rendered_component).to have_text("Undisclosed")
          expect(rendered_component).to have_no_link("Hidden subject")
        end
      end
    end
  end
end
