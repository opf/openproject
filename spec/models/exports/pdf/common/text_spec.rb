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

RSpec.describe Exports::PDF::Common::Text do
  subject(:text_painter) do
    Class.new do
      include Exports::PDF::Common::Text

      def initialize(pdf)
        @pdf = pdf
      end
    end.new(pdf)
  end

  let(:pdf) do
    Prawn::Document.new.tap do |document|
      font_path = Rails.public_path.join("fonts/noto")
      document.font_families.update("NotoSans" => { normal: font_path.join("NotoSans-Regular.ttf").to_s,
                                                    bold: font_path.join("NotoSans-Bold.ttf").to_s })
      document.font("NotoSans")
    end
  end
  let(:font_size) { 8 }
  let(:cell_top) { 100.0 }
  let(:cell_width) { 200.0 }
  let(:cell_height) { 22.0 }
  let(:rendered_text) { PDF::Inspector::Text.analyze(pdf.render) }
  let(:baselines) { rendered_text.positions.map(&:last) }

  def paint_cell(text)
    text_painter.paint_fitted_text(text, 0.0, cell_top, cell_width, cell_height, size: font_size, max_lines: 2)
  end

  # Vertical center of the visible text: cap height of the first line to half the descender of the last
  def ink_center
    ttf = pdf.font.ttf
    cap_height = ttf.os2.cap_height.to_f / ttf.header.units_per_em * font_size
    descender = -ttf.horizontal_header.descent.to_f / ttf.header.units_per_em * font_size
    (baselines.max + cap_height + baselines.min - (descender / 2)) / 2
  end

  def cell_center
    pdf.bounds.absolute_top - cell_top - (cell_height / 2)
  end

  describe "vertical centering" do
    it "centers a single line in the cell" do
      paint_cell("Short")

      expect(baselines.size).to eq(1)
      expect(ink_center).to be_within(0.2).of(cell_center)
    end

    it "centers two lines in the cell" do
      paint_cell("A much longer subject that needs two lines and then even more text so it gets cut off at the end")

      expect(baselines.size).to eq(2)
      expect(ink_center).to be_within(0.2).of(cell_center)
    end
  end

  describe "ellipsis" do
    let(:long_text) { "Supercalifragilisticexpialidocious Pneumonoultramicroscopicsilicovolcanoconiosis " * 4 }
    let(:painted_lines) { rendered_text.strings }

    before { paint_cell(long_text) }

    it "fills the last line up to the cell width, cutting within a word" do
      shown = painted_lines.last.delete_suffix("...")
      shown_so_far = "#{painted_lines.first} #{shown}"

      expect(painted_lines.size).to eq(2)
      expect(painted_lines.last).to end_with("...")
      expect(long_text).to start_with(shown_so_far)
      expect(long_text[shown_so_far.length]).not_to eq(" ")
      expect(pdf.width_of(painted_lines.last, size: font_size)).to be > (cell_width - pdf.width_of("m", size: font_size))
    end
  end
end
