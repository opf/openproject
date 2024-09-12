# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe OpenProject::HtmlDiff do
  describe ".from_markdown" do
    it "hightlights additions with <ins> tags" do
      from = ""
      to = "Hello, world!"
      expect(described_class.from_markdown(from, to))
        .to eq(<<~HTML.strip)
          <p class="op-uc-p"><ins class="diffins">Hello, world!</ins></p>
        HTML
    end

    it "hightlights removals with <del> tags" do
      from = "Hello, world!"
      to = ""
      expect(described_class.from_markdown(from, to))
        .to eq(<<~HTML.strip)
          <p class="op-uc-p"><del class="diffdel">Hello, world!</del></p>
        HTML
    end

    it "hightlights modifications with both <ins> and <del> tags" do
      from = "Hello, world!"
      to = "Hello, OpenProject!"
      expect(described_class.from_markdown(from, to))
        .to eq(<<~HTML.strip)
          <p class="op-uc-p">Hello, <del class="diffmod">world!</del><ins class="diffmod">OpenProject!</ins></p>
        HTML
    end

    context "with a list" do
      it "removes extra newlines from the diff" do # rubocop:disable RSpec/ExampleLength
        from = <<~MARKDOWN
          Deletion:

          *   Item 1

          *   Item 2

          Insertion:

          *   Item A
        MARKDOWN
        to = <<~MARKDOWN
          Deletion:

          *   Item 1

          Insertion:

          *   Item A

          *   Item B
        MARKDOWN
        expect(described_class.from_markdown(from, to))
          .to eq(<<~HTML.strip)
            <p class="op-uc-p">Deletion:</p>
            <ul class="op-uc-list">
            <li class="op-uc-list--item">
            <p class="op-uc-p">Item 1</p>
            </li>
            <li class="op-uc-list--item">
            <p class="op-uc-p"><del class="diffdel">Item 2</del></p>
            </li>
            </ul>
            <p class="op-uc-p">Insertion:</p>
            <ul class="op-uc-list">
            <li class="op-uc-list--item">
            <p class="op-uc-p">Item A</p>
            </li>
            <li class="op-uc-list--item">
            <p class="op-uc-p"><ins class="diffins">Item B</ins></p>
            </li>
            </ul>
          HTML
      end
    end
  end
end
