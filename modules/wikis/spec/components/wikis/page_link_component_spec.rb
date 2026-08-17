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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::PageLinkComponent, type: :component do
  let(:provider) { build_stubbed(:internal_wiki_provider) }
  let(:page_info) do
    Wikis::Adapters::Results::PageInfo.new(
      identifier: "stormtrooper_training",
      title: "Stormtrooper training",
      provider:,
      href: "https://wiki.death.star/Home/stormtrooper_training"
    )
  end
  let(:page_info_result) { Success(page_info) }
  let(:menu_actions) { [] }
  let(:source) { nil }

  subject(:render_component) { render_inline(described_class.new(page_info_result, menu_actions:, source:)) }

  before { render_component }

  it "renders the page link successfully" do
    expect(page).to have_link(text: page_info.title, href: page_info.href)
  end

  context "when the page is referenced as a parent" do
    let(:source) { :parent }

    it "renders the parent badge" do
      expect(page).to have_test_selector("wiki-page-link-source-badge",
                                         text: I18n.t("wikis.page_links.source.parent"))
    end
  end

  context "when the page is referenced as a mention" do
    let(:source) { :mention }

    it "renders no badge" do
      expect(page).not_to have_test_selector("wiki-page-link-source-badge")
    end
  end

  context "when the page has no source" do
    it "renders no badge" do
      expect(page).not_to have_test_selector("wiki-page-link-source-badge")
    end
  end

  context "when given menu actions" do
    let(:menu_actions) do
      [instance_double(Wikis::PageLinkComponent::RemoveAction,
                       icon: :trash,
                       menu_item_args: { label: "Remove page link", tag: :a, href: "/remove", scheme: :danger })]
    end

    it "renders the action menu with the provided actions" do
      expect(page).to have_test_selector("wiki-page-link-action-menu")
      expect(page).to have_link("Remove page link", href: "/remove")
    end
  end

  context "when a menu action is disabled" do
    let(:menu_actions) do
      [instance_double(Wikis::PageLinkComponent::AddToRelatedAction,
                       icon: :plus,
                       menu_item_args: { label: "Add to related pages", disabled: true })]
    end

    it "renders the action as disabled" do
      expect(page).to have_css("[aria-disabled='true']", text: "Add to related pages")
    end
  end

  context "when given no menu actions" do
    it "does not render the action menu" do
      expect(page).not_to have_test_selector("wiki-page-link-action-menu")
    end
  end

  context "if there are errors retrieving the page info" do
    let(:page_info_result) do
      Failure(
        SimpleError.new(
          source: Wikis::Adapters::Providers::Internal::Queries::PageInfo,
          code: error_code
        )
      )
    end

    context "if the page was not found" do
      let(:error_code) { :not_found }

      it "renders an error text" do
        expect(page).not_to have_link
        expect(page).to have_text(I18n.t("wikis.page_links.errors.page_not_found"))
      end
    end

    context "if the page access is forbidden" do
      let(:error_code) { :forbidden }

      it "renders an error text" do
        expect(page).not_to have_link
        expect(page).to have_text(I18n.t("wikis.page_links.errors.page_access_forbidden"))
      end
    end

    context "if an unknown error occurred" do
      let(:error_code) { :timeout }

      it "renders an error text" do
        expect(page).not_to have_link
        expect(page).to have_text(I18n.t("wikis.page_links.errors.unexpected"))
      end
    end
  end
end
