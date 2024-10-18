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

RSpec.describe SortHelper do
  describe "#sort_init/#sort_update/#sort_clause" do
    # Needed to mimic being included in a controller
    def controller_name; "foo"; end

    def action_name; "bar"; end

    before do
      sort_init "attr1", "desc"
    end

    context "with arrays" do
      before do
        sort_update(%w[attr1 attr2])
      end

      it "returns the first attr in descending order" do
        expect(sort_clause)
          .to eql "attr1 DESC"
      end
    end

    context "with hashes" do
      before do
        sort_update("attr1" => "table1.attr1", "attr2" => "table2.attr2")
      end

      it "returns the first attr in descending order with the table name prefixed" do
        expect(sort_clause)
          .to eql "table1.attr1 DESC"
      end
    end

    context "with hashes sorting by multiple values" do
      before do
        sort_update("attr1" => %w[table1.attr1 table1.attr2], "attr2" => "table2.attr2")
      end

      it "returns the first attr in descending order" do
        expect(sort_clause)
          .to eql "table1.attr1 DESC, table1.attr2 DESC"
      end
    end
  end

  describe "#sort_init/#sort_update/params/session" do
    # Needed to mimic being included in a controller
    def controller_name; "foo"; end

    def action_name; "bar"; end

    def params; { sort: sort_param }; end

    def session; @session ||= {}; end

    before do
      sort_init "attr1", "desc"
      sort_update("attr1" => %w[table1.attr1 table1.attr2], "attr2" => "table2.attr2")
    end

    context "with valid sort params" do
      let(:sort_param) { "attr1,attr2:desc" }

      it "persists the order in the session" do
        expect(session["foo_bar_sort"])
          .to eql "attr1,attr2:desc"
      end
    end

    context "with invalid sort key" do
      let(:sort_param) { "invalid_key" }

      it "keeps the default sort in the session" do
        expect(session["foo_bar_sort"])
          .to eql "attr1:desc"
      end
    end

    context "with invalid sort direction" do
      let(:sort_param) { "attr1:blubs,attr2" }

      it "falls back to the default sort order in the session" do
        expect(session["foo_bar_sort"])
          .to eql "attr1,attr2"
      end
    end
  end

  describe "#sort_header_tag" do
    subject(:output) do
      helper.sort_header_tag("id", **options)
    end

    let(:options) { {} }
    let(:sort_key) { "" }
    let(:sort_asc) { true }
    let(:sort_criteria) do
      instance_double(SortHelper::SortCriteria,
                      first_key: sort_key,
                      first_asc?: sort_asc,
                      to_param: "sort_criteria_params").as_null_object
    end

    before do
      # helper relies on this instance var
      @sort_criteria = sort_criteria

      # fake having called '/work_packages'
      allow(helper)
        .to receive(:url_options)
        .and_return(url_options.merge(controller: "work_packages", action: "index"))
    end

    it "renders a th with a sort link" do
      expect(output).to be_html_eql(<<-HTML)
        <th title="Sort by &quot;Id&quot;">
          <div class="generic-table--sort-header-outer">
            <div class="generic-table--sort-header">
              <span>
                <a href="/work_packages?sort=sort_criteria_params"
                   rel="nofollow"
                   title="Sort by &quot;Id&quot;">Id</a>
              </span>
            </div>
          </div>
        </th>
      HTML
    end

    context "when sorting by the column" do
      let(:sort_key) { "id" }

      it "adds the sort class" do
        expect(output).to be_html_eql(<<-HTML)
          <th title="Ascending sorted by &quot;Id&quot;">
            <div class="generic-table--sort-header-outer">
              <div class="generic-table--sort-header">
                <span class="sort asc">
                  <a href="/work_packages?sort=sort_criteria_params"
                     rel="nofollow"
                     title="Ascending sorted by &quot;Id&quot;">Id</a>
                </span>
              </div>
            </div>
          </th>
        HTML
      end
    end

    context "when sorting desc by the column" do
      let(:sort_key) { "id" }
      let(:sort_asc) { false }

      it "adds the sort class" do
        expect(output).to be_html_eql(<<-HTML)
          <th title="Descending sorted by &quot;Id&quot;">
            <div class="generic-table--sort-header-outer">
              <div class="generic-table--sort-header">
                <span class="sort desc">
                  <a href="/work_packages?sort=sort_criteria_params"
                     rel="nofollow"
                     title="Descending sorted by &quot;Id&quot;">Id</a>
                </span>
              </div>
            </div>
          </th>
        HTML
      end
    end

    describe "copying parameters" do
      before do
        controller.params = ActionController::Parameters.new(
          filters: "xyz",
          per_page: "42",
          expand: "nope",
          columns: "a,b,c",
          foo: "bar",
          bar: "baz",
          baz: "foo"
        )
      end

      context "when not given allowed parameters" do
        it "copies default ones to the link" do
          expect(output).to be_html_eql(<<-HTML)
            <th title="Sort by &quot;Id&quot;">
              <div class="generic-table--sort-header-outer">
                <div class="generic-table--sort-header">
                  <span>
                    <a href="/work_packages?columns=a%2Cb%2Cc&amp;expand=nope&amp;filters=xyz&amp;per_page=42&amp;sort=sort_criteria_params"
                       rel="nofollow"
                       title="Sort by &quot;Id&quot;">Id</a>
                  </span>
                </div>
              </div>
            </th>
          HTML
        end
      end

      context "when given allowed parameters" do
        let(:options) { { allowed_params: %w[foo baz lol] } }

        it "copies them to the link" do
          expect(output).to be_html_eql(<<-HTML)
            <th title="Sort by &quot;Id&quot;">
              <div class="generic-table--sort-header-outer">
                <div class="generic-table--sort-header">
                  <span>
                    <a href="/work_packages?baz=foo&amp;foo=bar&amp;sort=sort_criteria_params"
                       rel="nofollow"
                       title="Sort by &quot;Id&quot;">Id</a>
                  </span>
                </div>
              </div>
            </th>
          HTML
        end
      end
    end

    describe "passing data params" do
      let(:options) { { data: { "turbo-stream": true } } }

      it "includes the passed data param in the link" do
        expect(output).to be_html_eql(<<~HTML)
          <th title="Sort by &quot;Id&quot;">
            <div class="generic-table--sort-header-outer">
              <div class="generic-table--sort-header">
                <span>
                  <a title="Sort by &quot;Id&quot;" data-turbo-stream="true" rel="nofollow" href="/work_packages?sort=sort_criteria_params">
                    Id
                  </a>
                </span>
              </div>
            </div>
          </th>
        HTML
      end
    end
  end

  describe "#sort_header_with_action_menu" do
    subject(:output) do
      helper.sort_header_with_action_menu("id",
                                          %w[name id description], {}, **options)
    end

    let(:options) { { param: :json, sortable: true } }
    let(:sort_criteria) { SortHelper::SortCriteria.new }

    let(:action_menu) do
      # The resulting HTML is too big to assert in detail. We will only check some key parts to ensure it is
      # an action menu with the expected content.
      Nokogiri::HTML(output).at_css("th .generic-table--sort-header action-menu")
    end

    before do
      # helper relies on this instance var
      @sort_criteria = sort_criteria

      # fake having called '/projects'
      allow(helper)
        .to receive(:url_options)
              .and_return(url_options.merge(controller: "projects", action: "index"))
    end

    it "renders an action-menu button as column header" do
      expect(action_menu.at_css("button#menu-id-button .Button-content .Button-label").text).to eq("Id")
    end

    it "shows sorting actions in the action-menu" do
      sort_desc = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-sort-desc']")
      expect(sort_desc.at_css(".ActionListItem-label").text.strip).to eq("Sort descending")
      expect(sort_desc["href"]).to eq("/projects?sortBy=%5B%5B%22id%22%2C%22desc%22%5D%5D")

      sort_asc = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-sort-asc']")
      expect(sort_asc.at_css(".ActionListItem-label").text.strip).to eq("Sort ascending")
      expect(sort_asc["href"]).to eq("/projects?sortBy=%5B%5B%22id%22%2C%22asc%22%5D%5D")
    end

    context "with a column that is not sortable" do
      let(:options) { { param: :json, sortable: false } }

      it "does not show the sorting actions in the action-menu" do
        expect(action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-sort-desc']")).to be_nil

        expect(action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-sort-asc']")).to be_nil
      end
    end

    it "shows an action to move columns left and right" do
      move_left = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-move-col-left']")
      expect(move_left.at_css(".ActionListItem-label").text.strip).to eq("Move column left")
      # The id column moved one place to the left and is now the first column instead of the second.
      expect(move_left["href"]).to eq("/projects?columns=id+name+description")

      move_right = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-move-col-right']")
      expect(move_right.at_css(".ActionListItem-label").text.strip).to eq("Move column right")
      # The id column moved one place to the right and is now the last one.
      expect(move_right["href"]).to eq("/projects?columns=name+description+id")
    end

    context "with the current column being the leftmost one" do
      subject(:output) do
        helper.sort_header_with_action_menu("id",
                                            %w[id name description], {}, **options)
      end

      it "does not offer a 'move left' option" do
        move_left = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-move-col-left']")
        expect(move_left).to be_nil

        # But it offers a 'move right' option
        move_right = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-move-col-right']")
        expect(move_right).not_to be_nil
      end
    end

    context "with the current column being the rightmost one" do
      subject(:output) do
        helper.sort_header_with_action_menu("id",
                                            %w[name description id], {}, **options)
      end

      it "does not offer a 'move right' option" do
        move_right = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-move-col-right']")
        expect(move_right).to be_nil

        # But it offers a 'move left' option
        move_left = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-move-col-left']")
        expect(move_left).not_to be_nil
      end
    end

    it "shows an action to add columns" do
      add_col = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-add-column']")
      expect(add_col.at_css(".ActionListItem-label").text.strip).to eq("Add column")
      # Check that the 'ConfigureViewModal' is opened on link click. This is where adding columns happens.
      expect(add_col["href"]).to eq("/project_queries/configure_view_modal")
    end

    it "shows an action to remove a column" do
      remove_col = action_menu.at_css("action-list .ActionListItem a[data-test-selector='id-remove-column']")
      expect(remove_col.at_css(".ActionListItem-label").text.strip).to eq("Remove column")
      # The current column is removed from the columns-query:
      expect(remove_col["href"]).to eq("/projects?columns=name+description")
    end

    it "shows a 'filter by' action" do
      filter_by = action_menu.at_css("action-list .ActionListItem button[data-test-selector='id-filter-by']")
      expect(filter_by.at_css(".ActionListItem-label").text.strip).to eq("Filter by")
      # Check that the correct Stimulus controller with the correct data is referenced:
      expect(filter_by["data-action"]).to eq("table-action-menu#filterBy")
      expect(filter_by["data-filter-name"]).to eq("id")
    end

    context "with a filter mapping for the column" do
      subject(:output) do
        helper.sort_header_with_action_menu("id",
                                            %w[name id description], { "id" => "id_code" }, **options)
      end

      it "shows a 'filter by' action with the mapped filter" do
        filter_by = action_menu.at_css("action-list .ActionListItem button[data-test-selector='id-filter-by']")
        expect(filter_by.at_css(".ActionListItem-label").text.strip).to eq("Filter by")
        expect(filter_by["data-action"]).to eq("table-action-menu#filterBy")
        # With a column mapping, the filter name is changed accordingly:
        expect(filter_by["data-filter-name"]).to eq("id_code")
      end
    end

    context "with the filter mapping specifying there is no filter for the column" do
      subject(:output) do
        # With the filter name mapped to nil, we expect no filter action to be present.
        helper.sort_header_with_action_menu("id",
                                            %w[name id description], { "id" => nil }, **options)
      end

      it "does not show a 'filter by' action" do
        filter_by = action_menu.at_css("action-list .ActionListItem button[data-test-selector='id-filter-by']")
        expect(filter_by).to be_nil
      end
    end
  end
end
