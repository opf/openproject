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

RSpec.describe Import::JiraWikiMarkup::Parser do
  subject(:parser) { described_class.new("") }

  # Macro headers survive only as far as the AST: the renderer uses the language
  # but discards params, so these contracts are not observable end to end.
  describe "#parse_code_block_header" do
    subject(:header) { parser.send(:parse_code_block_header, raw) }

    context "with no header" do
      let(:raw) { nil }

      it { is_expected.to eq([nil, {}]) }
    end

    context "with an empty header" do
      let(:raw) { "" }

      it { is_expected.to eq([nil, {}]) }
    end

    context "with a header of separators only" do
      let(:raw) { "||" }

      it { is_expected.to eq([nil, {}]) }
    end

    context "with a language only" do
      let(:raw) { " java " }

      it { is_expected.to eq(["java", {}]) }
    end

    context "with a language and parameters" do
      let(:raw) { "java|title=Bar.java|borderStyle=solid" }

      it { is_expected.to eq(["java", { "title" => "Bar.java", "borderStyle" => "solid" }]) }
    end

    context "with parameters but no language" do
      let(:raw) { "title=Bar.java|borderStyle=solid" }

      it { is_expected.to eq([nil, { "title" => "Bar.java", "borderStyle" => "solid" }]) }
    end
  end

  describe "#parse_macro_params" do
    subject(:params) { parser.send(:parse_macro_params, raw) }

    context "with no parameters" do
      let(:raw) { nil }

      it { is_expected.to eq({}) }
    end

    context "with separators but no assignments" do
      let(:raw) { "|" }

      it { is_expected.to eq({}) }
    end

    context "with surrounding whitespace" do
      let(:raw) { " a = 1 " }

      it { is_expected.to eq({ "a" => "1" }) }
    end

    context "with a segment that has no value" do
      let(:raw) { "a=" }

      it { is_expected.to eq({ "a" => "" }) }
    end

    context "with a segment that is not an assignment" do
      let(:raw) { "a=1|junk|b=2" }

      it "ignores the segment" do
        expect(params).to eq({ "a" => "1", "b" => "2" })
      end
    end
  end

  describe "#parse_image_params" do
    subject(:params) { parser.send(:parse_image_params, raw) }

    context "with a bare word" do
      let(:raw) { "alt text" }

      it { is_expected.to eq({ "alt" => "alt text" }) }
    end

    context "with the thumbnail keyword" do
      let(:raw) { "alt text,thumbnail" }

      it { is_expected.to eq({ "alt" => "alt text", "thumbnail" => true }) }
    end

    context "with dimensions" do
      let(:raw) { "width=100,height=50" }

      it { is_expected.to eq({ "width" => "100", "height" => "50" }) }
    end
  end

  # Every block handler has to advance parse_blocks, or it loops forever.
  describe "#consume_delimited_block" do
    subject(:block) { parser.send(:consume_delimited_block, lines, 0, "code") }

    context "when the closing tag is missing" do
      let(:lines) { ["{code}", "body"] }

      it "collects the remaining lines" do
        expect(block.first).to eq("body")
      end

      it "advances past the end of the input" do
        expect(block.last).to be > lines.length - 1
      end
    end

    context "when the closing tag trails the last line" do
      let(:lines) { ["{code}", "body{code}"] }

      it "strips the tag from the content" do
        expect(block.first).to eq("body")
      end
    end
  end

  # The header flag on a cell, and which row becomes the head, are the contract the
  # renderer reads. Asserting them here keeps a change to the separator rules from
  # hiding behind whatever HTML it happens to produce.
  describe "#consume_table" do
    subject(:result) { parser.send(:consume_table, lines, 0) }

    let(:table) { result.first }

    def row_header_flags(row) = row.map(&:header)
    def header_flags(rows) = rows.map { |row| row_header_flags(row) }

    context "with a header row and a data row" do
      let(:lines) { ["||A||B||", "|1|2|"] }

      it "takes the header row as the head" do
        expect(row_header_flags(table.header)).to eq([true, true])
      end

      it "keeps the data row in the body" do
        expect(header_flags(table.rows)).to eq([[false, false]])
      end

      it "consumes both lines" do
        expect(result.last).to eq(2)
      end
    end

    context "without a header row" do
      let(:lines) { ["|1|2|"] }

      it "has no head" do
        expect(table.header).to be_nil
      end

      it "holds only data cells" do
        expect(header_flags(table.rows)).to eq([[false, false]])
      end
    end

    context "with a header column" do
      let(:lines) { ["||Name|Alice|"] }

      it "marks only the leading cell as a header cell" do
        expect(header_flags(table.rows)).to eq([[true, false]])
      end

      it "does not mistake the mixed row for a head" do
        expect(table.header).to be_nil
      end
    end

    context "with a run of header rows" do
      let(:lines) { ["||Field||Details||", "||OS||Windows||"] }

      it "takes only the first as the head" do
        expect(row_header_flags(table.header)).to eq([true, true])
      end

      it "keeps the rest as body rows of header cells" do
        expect(header_flags(table.rows)).to eq([[true, true]])
      end
    end

    context "with markup in a cell" do
      let(:lines) { ["|*bold*|"] }

      it "parses the cell contents rather than storing the raw text" do
        expect(table.rows.first.first.children.first).to be_a(Import::JiraWikiMarkup::Nodes::Bold)
      end
    end

    context "when the starting line is not a row" do
      let(:lines) { ["|not a table"] }

      it "falls back to a paragraph rather than raising" do
        expect(table).to be_a(Import::JiraWikiMarkup::Nodes::Paragraph)
      end

      it "advances past the line so parsing terminates" do
        expect(result.last).to eq(1)
      end
    end

    context "when a cell macro never closes" do
      let(:lines) { ["|a|{code}", "never closed"] }

      it "falls back to a paragraph" do
        expect(table).to be_a(Import::JiraWikiMarkup::Nodes::Paragraph)
      end

      it "leaves the following lines for the block parser" do
        expect(result.last).to eq(1)
      end
    end
  end

  # The separator rules decide both how many cells a row has and which of them are
  # header cells, and a row that yields nothing has to be rejected here so the
  # caller can fall back.
  describe "#parse_cells" do
    subject(:cells) { parser.send(:parse_cells, row) }

    def contents(cells) = cells.map { |cell| cell.children.map(&:content).join }

    context "with only an opening separator" do
      let(:row) { "|not a row" }

      it { is_expected.to be_nil }
    end

    context "with separators but no content" do
      let(:row) { "||" }

      it { is_expected.to be_nil }
    end

    context "without a closing separator" do
      let(:row) { "|a|b" }

      it "still yields both cells" do
        expect(contents(cells)).to eq(%w[a b])
      end
    end

    context "with a closing separator" do
      let(:row) { "|a|b|" }

      it "does not add an empty trailing cell" do
        expect(contents(cells)).to eq(%w[a b])
      end
    end

    context "with a doubled separator" do
      let(:row) { "|a||b|" }

      it "reads it as a header cell rather than an empty one" do
        expect(cells.map(&:header)).to eq([false, true])
      end
    end

    context "with an escaped separator" do
      let(:row) { "|a\\|b|c|" }

      it "keeps it inside the cell" do
        expect(contents(cells)).to eq(["a|b", "c"])
      end
    end
  end

  # consume_list is only reached for lines matching a list block pattern, which
  # parse_list_line always accepts. These cover the contract it relies on, so a
  # future change to either regex cannot turn into a crash or an endless loop.
  describe "#consume_list" do
    subject(:result) { parser.send(:consume_list, lines, 0) }

    context "when the starting line yields no list item" do
      let(:lines) { ["not a list line"] }

      it "falls back to a paragraph rather than raising" do
        expect(result.first).to be_a(Import::JiraWikiMarkup::Nodes::Paragraph)
      end

      it "advances past the line so parsing terminates" do
        expect(result.last).to eq(1)
      end
    end

    context "when the starting line is a list item" do
      let(:lines) { ["* an item"] }

      it "builds the list" do
        expect(result.first).to be_a(Import::JiraWikiMarkup::Nodes::List)
      end
    end
  end
end
