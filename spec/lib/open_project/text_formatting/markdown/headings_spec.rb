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
               "headings" do
  include_context "expected markdown modules"

  describe ".format_text" do
    shared_examples_for "bem heading" do |level|
      it_behaves_like "format_text produces" do
        let(:raw) do
          <<~RAW
            Some text before

            #{'#' * level} the heading

            more text
          RAW
        end

        let(:expected) do
          <<~EXPECTED
            <p class="op-uc-p">Some text before</p>
            <h#{level} class="op-uc-h#{level}" id="the-heading">
              the heading
              <a class="op-uc-link_permalink icon-link op-uc-link" aria-hidden="true" href="#the-heading"></a>
            </h#{level}>
            <p class="op-uc-p">more text</p>
          EXPECTED
        end
      end
    end

    it_behaves_like "bem heading", 1
    it_behaves_like "bem heading", 2
    it_behaves_like "bem heading", 3
    it_behaves_like "bem heading", 4
    it_behaves_like "bem heading", 5
    it_behaves_like "bem heading", 6

    context "with the heading being in a code bock" do
      shared_examples_for "unchanged heading" do |level|
        it_behaves_like "format_text produces" do
          let(:raw) do
            <<~RAW
              Some text before

              ```
              <h#{level}>The heading </h#{level}>

              ```

              more text
            RAW
          end

          let(:expected) do
            <<~EXPECTED
              <p class="op-uc-p">Some text before</p>

              <pre class='op-uc-code-block'>
              &lt;h#{level}&gt;The heading &lt;/h#{level}&gt;

              </pre>

              <p class="op-uc-p">more text</p>
            EXPECTED
          end
        end
      end

      it_behaves_like "unchanged heading", 1
      it_behaves_like "unchanged heading", 2
      it_behaves_like "unchanged heading", 3
      it_behaves_like "unchanged heading", 4
      it_behaves_like "unchanged heading", 5
      it_behaves_like "unchanged heading", 6
    end

    context "with the heading being a date (number and backslash)" do
      it_behaves_like "format_text produces" do
        let(:raw) do
          '# 2009\02\09'
        end

        let(:expected) do
          <<~EXPECTED
            <h1 class="op-uc-h1" id="20090209">
              2009\\02\\09
              <a class="op-uc-link_permalink icon-link op-uc-link" href="#20090209" aria-hidden="true"></a>
            </h1>
          EXPECTED
        end
      end
    end
  end
end
