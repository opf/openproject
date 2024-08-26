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
end
