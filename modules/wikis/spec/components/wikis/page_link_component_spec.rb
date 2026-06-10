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
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:provider) { create(:internal_wiki_provider) }
  let(:page_link) { create(:relation_wiki_page_link, linkable: work_package, provider:) }
  let(:page_info) do
    Wikis::Adapters::Results::PageInfo.new(
      identifier: page_link.identifier,
      title: "Stormtrooper training",
      provider:,
      href: "https://wiki.death.star/Home/stormtrooper_training"
    )
  end
  let(:page_info_result) { Success(page_info) }
  let(:permissions) { [:manage_wiki_page_links] }
  let(:actions) { [] }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  subject(:render_component) { render_inline(described_class.new(page_info_result, actions:, page_link:)) }

  before { render_component }

  it "renders the page link successfully" do
    expect(page).to have_link(text: page_info.title, href: page_info.href)
  end

  context "when the page link has the remove action" do
    let(:actions) { [:remove] }

    context "when the user has no permission to manage wiki page links" do
      let(:permissions) { [] }

      it "does not render the action menu" do
        expect(page).not_to have_test_selector("wiki-page-link-action-menu")
      end
    end

    context "when the user has the permission to manage wiki page links" do
      it "shows the remove page link action in the action menu" do
        expect(page).to have_test_selector("wiki-page-link-action-menu")
      end
    end
  end

  context "when the page link has no actions" do
    it "does not render the action menu" do
      expect(page).not_to have_test_selector("wiki-page-link-action-menu")
    end
  end

  context "if there are errors retrieving the page info" do
    let(:page_info_result) do
      Failure(
        Wikis::Adapters::Results::Error.new(
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
