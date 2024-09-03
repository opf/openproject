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
require_relative "expected_markdown"

RSpec.describe OpenProject::TextFormatting,
               "tables" do
  include_context "expected markdown modules"

  context "for a markdown table" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          This is a table with header cells:

          |header|header|
          |------|------|
          |cell11|cell12|
          |cell21|cell22|
          |cell31|cell32|
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <p class="op-uc-p">This is a table with header cells:</p>
          <figure class="op-uc-figure">
            <div class="op-uc-figure--content">
              <table class="op-uc-table">
                <thead class="op-uc-table--head">
                  <tr class="op-uc-table--row">
                    <th class="op-uc-table--cell op-uc-table--cell_head">header</th>
                    <th class="op-uc-table--cell op-uc-table--cell_head">header</th>
                  </tr>
                </thead>
                <tbody>
                  <tr class="op-uc-table--row">
                    <td class="op-uc-table--cell">cell11</td>
                    <td class="op-uc-table--cell">cell12</td>
                  </tr>
                  <tr class="op-uc-table--row">
                    <td class="op-uc-table--cell">cell21</td>
                    <td class="op-uc-table--cell">cell22</td>
                  </tr>
                  <tr class="op-uc-table--row">
                    <td class="op-uc-table--cell">cell31</td>
                    <td class="op-uc-table--cell">cell32</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </figure>
        EXPECTED
      end
    end
  end

  context "for an html table" do
    it_behaves_like "format_text produces" do
      let(:raw) do
        <<~RAW
          <table>
            <thead class="op-uc-table--head">
              <tr>
                <th>header</th>
                <th>header</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>cell11</td>
                <td>cell12</td>
              </tr>
              <tr>
                <td>cell21</td>
                <td>cell22</td>
              </tr>
              <tr>
                <td>cell31</td>
                <td>cell32</td>
              </tr>
            </tbody>
          </table>
        RAW
      end

      let(:expected) do
        <<~EXPECTED
          <figure class="op-uc-figure">
            <div class="op-uc-figure--content">
              <table class="op-uc-table">
                <thead class="op-uc-table--head">
                  <tr class="op-uc-table--row">
                    <th class="op-uc-table--cell op-uc-table--cell_head">header</th>
                    <th class="op-uc-table--cell op-uc-table--cell_head">header</th>
                  </tr>
                </thead>
                <tbody>
                  <tr class="op-uc-table--row">
                    <td class="op-uc-table--cell">cell11</td>
                    <td class="op-uc-table--cell">cell12</td>
                  </tr>
                  <tr class="op-uc-table--row">
                    <td class="op-uc-table--cell">cell21</td>
                    <td class="op-uc-table--cell">cell22</td>
                  </tr>
                  <tr class="op-uc-table--row">
                    <td class="op-uc-table--cell">cell31</td>
                    <td class="op-uc-table--cell">cell32</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </figure>
        EXPECTED
      end
    end

    context "already having a figure parent element" do
      it_behaves_like "format_text produces" do
        let(:raw) do
          <<~RAW
            <figure>
              <div>
                <table>
                  <tbody>
                    <tr>
                      <td>cell11</td>
                      <td>cell12</td>
                    </tr>
                    <tr>
                      <td>cell21</td>
                      <td>cell22</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </figure>
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <figure class="op-uc-figure">
              <div class="op-uc-figure--content">
                <table class="op-uc-table">
                  <tbody>
                    <tr class="op-uc-table--row">
                      <td class="op-uc-table--cell">cell11</td>
                      <td class="op-uc-table--cell">cell12</td>
                    </tr>
                    <tr class="op-uc-table--row">
                      <td class="op-uc-table--cell">cell21</td>
                      <td class="op-uc-table--cell">cell22</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </figure>
          EXPECTED
        end
      end
    end
  end
end
