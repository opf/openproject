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

require "spec_helper"

RSpec.describe TableDataRowsFilter do
  subject(:page) { Capybara.string(html) }

  let(:head) { "<thead><tr><th>Flavor</th><th>Cones</th><th>Tubs</th></tr></thead>" }
  let(:body) do
    <<~HTML
      <tbody>
        <tr><th scope="row">Vanilla</th><td>40</td><td>40</td></tr>
        <tr><th scope="row">Pistachio</th><td></td><td>36</td></tr>
      </tbody>
    HTML
  end
  let(:html) { "<table><caption>Ice cream sales</caption>#{head}#{body}</table>" }

  let(:vanilla) { { "Flavor" => "Vanilla", "Cones" => "40", "Tubs" => "40" } }
  let(:pistachio) { { "Flavor" => "Pistachio", "Cones" => "", "Tubs" => "36" } }

  describe "data_rows:" do
    it "matches when every row is given" do
      expect(page).to have_table("Ice cream sales", data_rows: [vanilla, pistachio])
    end

    it "matches regardless of row order" do
      expect(page).to have_table("Ice cream sales", data_rows: [pistachio, vanilla])
    end

    it "does not match when a row is missing" do
      expect(page).to have_no_table("Ice cream sales", data_rows: [vanilla])
    end

    it "does not match a wrong cell value" do
      expect(page).to have_no_table("Ice cream sales", data_rows: [vanilla, pistachio.merge("Tubs" => "35")])
    end

    context "when the header row is the first row of a table without thead and tbody" do
      let(:html) do
        <<~HTML
          <table>
            <caption>Ice cream sales</caption>
            <tr><th>Flavor</th><th>Cones</th><th>Tubs</th></tr>
            <tr><th scope="row">Vanilla</th><td>40</td><td>40</td></tr>
            <tr><th scope="row">Pistachio</th><td></td><td>36</td></tr>
          </table>
        HTML
      end

      it "matches the data rows" do
        expect(page).to have_table("Ice cream sales", data_rows: [vanilla, pistachio])
      end
    end
  end

  describe "with_data_rows:" do
    it "matches a subset of rows" do
      expect(page).to have_table("Ice cream sales", with_data_rows: [pistachio])
    end

    it "matches a partial row" do
      expect(page).to have_table("Ice cream sales", with_data_rows: [{ "Tubs" => "36" }])
    end

    it "does not match cells taken from different rows" do
      expect(page).to have_no_table("Ice cream sales", with_data_rows: [{ "Flavor" => "Vanilla", "Tubs" => "36" }])
    end

    it "does not match the header row" do
      expect(page).to have_no_table("Ice cream sales", with_data_rows: [{ "Flavor" => "Flavor", "Cones" => "Cones" }])
    end

    it "does not match a value in the wrong column" do
      expect(page).to have_no_table("Ice cream sales", with_data_rows: [{ "Cones" => "36" }])
    end
  end
end
