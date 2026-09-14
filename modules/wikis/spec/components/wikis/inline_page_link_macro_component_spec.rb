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

RSpec.describe Wikis::InlinePageLinkMacroComponent, type: :component do
  let(:provider) { build_stubbed(:internal_wiki_provider) }
  let(:page_info) do
    Wikis::Adapters::Results::PageInfo.new(
      identifier: "1234",
      title: "Stormtrooper training",
      provider:,
      href: "https://wiki.death.star/Home/stormtrooper_training"
    )
  end
  let(:page_info_result) { Success(page_info) }
  let(:component) { described_class.new(page_info_result) }

  subject(:render_component) { render_inline(component) }

  before { render_component }

  context "when the page information is available" do
    it "renders an accessible link to the wiki page" do
      macro = page.find(".op-inline-macro")
      link = macro.find("a", text: page_info.title, exact_text: true)

      expect(link[:href]).to eq(page_info.href)
      expect(link["aria-label"]).to eq(
        "#{page_info.title}: A dynamic link to a wiki page placed using a macro."
      )
    end
  end

  context "when retrieving the page information fails" do
    let(:page_info_result) do
      Failure(
        SimpleError.new(
          source: Wikis::Adapters::Providers::Internal::Queries::PageInfo,
          code: error_code
        )
      )
    end

    shared_examples "an unresolved wiki page link" do |error_text|
      it "renders the error without a link" do
        macro = page.find(".op-inline-macro")

        expect(macro).to have_text(error_text)
        expect(macro).to have_no_link
      end
    end

    context "when the page was not found" do
      let(:error_code) { :not_found }

      it_behaves_like "an unresolved wiki page link", "Linked wiki page no longer available"
    end

    context "when access to the page is forbidden" do
      let(:error_code) { :forbidden }

      it_behaves_like "an unresolved wiki page link", "You do not have permission to access this wiki page"
    end

    context "when an unexpected error occurs" do
      let(:error_code) { :timeout }

      it_behaves_like "an unresolved wiki page link", "An unexpected error occurred"
    end
  end
end
