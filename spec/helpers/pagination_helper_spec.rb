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

RSpec.describe PaginationHelper do
  let(:paginator) do
    # creating a mock pagination object
    # this one is then identical (from the interface) to a active record
    paginator = WillPaginate::Collection.create(current_page, per_page) do |pager|
      result = Array.new(pager.per_page) { |i| i }

      pager.replace(result)

      unless pager.total_entries
        pager.total_entries = total_entries
      end
    end

    paginator
  end

  describe "#pagination_links_full" do
    let(:per_page) { 10 }
    let(:total_entries) { 55 }
    let(:offset) { 1 }
    let(:current_page) { 1 }
    let(:pages) { (1..(total_entries / per_page)) }

    subject(:pagination) { helper.pagination_links_full(paginator) }

    before do
      # setup the helpers environment as if the helper is rendered after having called
      # /work_packages
      url_options = helper.url_options

      allow(helper)
        .to receive(:params)
        .and_return(ActionController::Parameters.new(controller: "work_packages", action: "index"))
      allow(helper)
        .to receive(:url_options)
        .and_return(url_options.merge(controller: "work_packages", action: "index"))
    end

    it "is inside a 'pagination' div" do
      expect(pagination).to have_css("div.op-pagination")
    end

    it "renders a labelled nav element" do
      expect(pagination).to have_element "nav", aria: { label: "Pagination" }
    end

    it "renders the main pagination nav" do
      expect(pagination).to have_css("nav[aria-label='Pagination']")
    end

    it "renders the per-page options list" do
      expect(pagination).to have_css(".op-pagination--options")
      expect(pagination).to have_css("nav", accessible_name: "Items per page selection")
      expect(pagination).to have_css(".op-pagination--label", text: "Per page")
      expect(pagination).to have_css("a.Page", minimum: 1)
    end

    it "has a next page link" do
      expect(pagination).to have_link "Next" do |link|
        expect(link).to have_octicon :"chevron-right"
        expect(link["rel"]).to eq "next"
      end
    end

    it "does not have a previous page link" do
      expect(pagination).to have_no_link "Previous"
    end

    it "has links to every page except the current one" do
      pages.excluding(current_page).each do |page|
        path = work_packages_path(page:)
        expect(pagination).to have_link(page.to_s, href: path) do |link|
          expect(link["aria-label"]).to eq "Page #{page}"
          expect(link["aria-current"]).to be_nil
        end
      end
    end

    it "does not have a link to the current page" do
      expect(pagination).to have_no_link text: current_page, exact_text: true, current: "page"
    end

    it "renders the current page with aria-current" do
      expect(pagination).to have_element(aria: { current: "page" }, text: current_page.to_s) do |element|
        expect(element["aria-label"]).to eq "Page #{current_page}"
      end
    end

    it "shows the range of the entries displayed" do
      range = "(#{(current_page * per_page) - per_page + 1} - " +
              "#{current_page * per_page}/#{total_entries})"
      expect(pagination).to have_css(".op-pagination--range", text: range, aria: { live: "polite" })
    end

    it "has different urls if the params are specified as options" do
      params = { controller: "work_packages", action: "index" }

      pagination = helper.pagination_links_full(paginator, params:)

      (1..(total_entries / per_page)).each do |i|
        next if i == current_page

        href = work_packages_path({ page: i }.merge(params))

        expect(pagination).to have_link(i.to_s, href:) do |link|
          expect(link["aria-label"]).to eq "Page #{i}"
          expect(link["aria-current"]).to be_nil
        end
      end
    end

    describe "per page options" do
      context "with multiple per page", with_settings: { per_page_options: "10,50,100" } do
        it "renders per page options" do
          expect(pagination).to have_css ".op-pagination--options"
        end

        it "renders a labelled nav element" do
          expect(pagination).to have_element "nav", aria: { label: "Items per page selection" }
        end

        it "has a link to every per page option" do
          expect(pagination).to have_css(".op-pagination--options") do |pagination_options|
            [10, 50, 100].each do |other_per_page|
              path = work_packages_path(page: current_page, per_page: other_per_page)
              expect(pagination_options).to have_link href: path do |link|
                expect(link["aria-label"]).to eq "Show #{other_per_page} per page"
              end
            end
          end
        end

        it "marks the current per page option with aria-current" do
          expect(pagination).to have_css(".op-pagination--options") do |pagination_options|
            expect(pagination_options).to have_link(per_page.to_s) do |link|
              expect(link["aria-label"]).to eq "Show #{per_page} per page"
              expect(link["aria-current"]).to eq "page"
              expect(link["class"]).to include("Page")
            end
          end
        end
      end

      context "with no per page", with_settings: { per_page_options: "" } do
        it "renders per page options" do
          expect(pagination).to have_no_css ".op-pagination--options"
        end

        it "does not render a labelled nav element" do
          expect(pagination).to have_no_element "nav", aria: { label: "Items per page selection" }
        end
      end
    end

    describe "WHEN the first page is the current" do
      let(:current_page) { 1 }

      it "deactivates the previous page link" do
        expect(pagination).to have_no_link "Previous"
      end

      it "has a link to the next page" do
        path = work_packages_path(page: current_page + 1)
        expect(pagination).to have_link "Next", href: path
      end
    end

    describe "WHEN the last page is the current" do
      let(:current_page) { (total_entries / per_page) + 1 }

      it "deactivates the next page link" do
        expect(pagination).to have_no_link "Next"
      end

      it "has a link to the previous page" do
        path = work_packages_path(page: current_page - 1)
        expect(pagination).to have_link "Previous", href: path
      end
    end

    describe "WHEN the paginated object is empty" do
      let(:total_entries) { 0 }

      it "shows no pages" do
        expect(pagination).to have_no_css(".op-pagination--items .op-pagination--item")
      end

      it "shows no pagination" do
        expect(pagination).to have_no_css(".op-pagination")
      end

      it "does not render a labelled nav element" do
        expect(pagination).to have_no_element "nav", aria: { label: "Pagination" }
      end
    end
  end

  describe "#page_param" do
    it "returns page if provided and sensible" do
      page = 2

      expect(page_param(page:)).to eq(page)
    end

    it "returns default page 1 if page provided but useless" do
      page = 0

      expect(page_param(page:)).to eq(1)
    end

    context "with multiples per_page",
            with_settings: { per_page_options: "5,10,15" } do
      it "calculates page from offset and limit if page is not provided" do
        # need to change settings as only multiples of per_page
        # are allowed for limit
        offset = 55
        limit = 10

        expect(page_param(offset:, limit:)).to eq(6)
      end
    end

    it "ignores offset and limit if page is provided" do
      offset = 55
      limit = 10
      page = 7

      expect(page_param(offset:, limit:, page:)).to eq(page)
    end

    context "faulty settings",
            with_settings: { per_page_options: "-1,2,3" } do
      it "does not break if limit is bogus (also faulty settings)" do
        offset = 55
        limit = "lorem"

        expect(page_param(offset:, limit:)).to eq(28)
      end
    end

    it "returns 1 if nothing is provided" do
      expect(page_param({})).to eq(1)
    end
  end

  describe "#per_page_param",
           with_settings: { per_page_options: "1,2,3" } do
    it "returns per_page if provided and one of the values stored in the settings" do
      per_page = 2

      expect(per_page_param(per_page:)).to eq(per_page)
    end

    it "returns per_page if provided and store it in the session" do
      session[:per_page] = 3
      per_page = 2

      expect(per_page_param(per_page:)).to eq(per_page)
      expect(session[:per_page]).to eq(2)
    end

    it "takes the smallest value stored in the settings if provided per_page param is not one of the configured" do
      per_page = 4

      expect(per_page_param(per_page:)).to eq(1)
    end

    it "prefers the value stored in the session if it is valid according to the settings" do
      session[:per_page] = 2

      expect(per_page_param(per_page: 3)).to eq(session[:per_page])
    end

    it "ignores the value stored in the session if it is not valid according to the settings" do
      session[:per_page] = 4

      expect(per_page_param(per_page: 3)).to eq(3)
    end

    it "uses limit synonymously to per_page" do
      limit = 2

      expect(per_page_param(limit:)).to eq(limit)
    end

    it "prefers per_page over limit" do
      limit = 2
      per_page = 3

      expect(per_page_param(limit:, per_page:)).to eq(per_page)
    end

    it "stores the value in the session" do
      limit = 2

      per_page_param(limit:)

      expect(session[:per_page]).to eq(limit)
    end
  end
end
