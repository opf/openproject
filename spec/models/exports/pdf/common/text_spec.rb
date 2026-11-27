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
  let(:style) { { font: "NotoSans", size: font_size } }
  let(:cell_top) { 100.0 }
  let(:cell_width) { 200.0 }
  let(:cell_height) { 22.0 }
  let(:long_text) { "Supercalifragilisticexpialidocious Pneumonoultramicroscopicsilicovolcanoconiosis " * 4 }
  let(:rendered_text) { PDF::Inspector::Text.analyze(pdf.render) }
  let(:painted_strings) { rendered_text.strings }
  let(:positions) { rendered_text.positions }
  let(:baselines) { positions.map(&:last) }

  def width_of(text, text_style = style)
    text_painter.measure_text_width(text, text_style)
  end

  def paint_cell(text, **)
    text_painter.paint_fitted_text(text, 0.0, cell_top, cell_width, cell_height, size: font_size, max_lines: 2, **)
  end

  # Vertical center of the visible text: cap height of the first line to the baseline of the last
  def ink_center
    ttf = pdf.font.ttf
    cap_height = ttf.os2.cap_height.to_f / ttf.header.units_per_em * font_size
    (baselines.max + cap_height + baselines.min) / 2
  end

  def cell_center
    pdf.bounds.absolute_top - cell_top - (cell_height / 2)
  end

  describe "#measure_text_width" do
    it "measures with the given font style" do
      expect(width_of("Subject", style.merge(style: :bold))).to be > width_of("Subject")
    end

    it "measures with the given size" do
      expect(width_of("Subject", style.merge(size: 16))).to be_within(0.01).of(width_of("Subject") * 2)
    end
  end

  describe "#measure_text_height" do
    it "grows with the number of lines" do
      single = text_painter.measure_text_height("Subject", style)

      expect(text_painter.measure_text_height("Subject\nSubject", style)).to be_within(0.01).of(single * 2)
    end
  end

  describe "#truncate_ellipsis" do
    let(:width) { 60.0 }

    it "keeps as much text as fits, without a space before the ellipsis" do
      truncated = text_painter.truncate_ellipsis("Supercalifragilistic expialidocious", width, style)

      expect(truncated).to end_with("...")
      expect(truncated).not_to include(" ...")
      expect(width_of(truncated)).to be <= width
      expect(width_of(truncated.sub("...", "m..."))).to be > width
    end

    it "measures with the given font style" do
      text = "Supercalifragilisticexpialidocious"

      expect(text_painter.truncate_ellipsis(text, width, style.merge(style: :bold)).length)
        .to be < text_painter.truncate_ellipsis(text, width, style).length
    end

    it "returns only the ellipsis when not even one character fits" do
      expect(text_painter.truncate_ellipsis("Subject", 1.0, style)).to eq("...")
    end
  end

  describe "#ellipsis_if_longer" do
    it "returns text that fits unchanged" do
      expect(text_painter.ellipsis_if_longer("Short", cell_width, style)).to eq("Short")
    end

    it "truncates text that does not fit" do
      truncated = text_painter.ellipsis_if_longer(long_text, cell_width, style)

      expect(truncated).to end_with("...")
      expect(width_of(truncated)).to be <= cell_width
    end
  end

  describe "#split_wrapped_lines" do
    it "splits the text into lines that each fit the width" do
      lines = text_painter.split_wrapped_lines(long_text, cell_width, style)

      expect(lines.size).to be > 1
      expect(lines.map { |line| width_of(line) }).to all(be <= cell_width)
      expect(lines.join(" ")).to eq(long_text.strip)
    end
  end

  describe "#wrap_to_lines" do
    it "returns short text unchanged" do
      expect(text_painter.wrap_to_lines("Short", cell_width, style, 2)).to eq(["Short"])
    end

    it "keeps all lines when they do not exceed the maximum" do
      lines = text_painter.wrap_to_lines(long_text, cell_width, style, 100)

      expect(lines.join(" ")).to eq(long_text.strip)
    end

    it "fills the last allowed line with the remaining text, cutting within a word" do
      lines = text_painter.wrap_to_lines(long_text, cell_width, style, 2)
      shown_so_far = "#{lines.first} #{lines.last.delete_suffix('...')}"

      expect(lines.size).to eq(2)
      expect(lines.last).to end_with("...")
      expect(long_text).to start_with(shown_so_far)
      expect(long_text[shown_so_far.length]).not_to eq(" ")
    end
  end

  describe "#text_from_last_line" do
    it "returns the text from the start of the last line to the end" do
      text = "First line\nsecond line and the rest"

      expect(text_painter.text_from_last_line(text, ["First line", "second line"])).to eq("second line and the rest")
    end

    it "replaces line breaks in the rest with spaces" do
      text = "First\nsecond\nthird"

      expect(text_painter.text_from_last_line(text, %w[First second])).to eq("second third")
    end
  end

  describe "#fit_lines" do
    let(:font_options) { { size: font_size, style: :normal, leading: 0 } }

    it "returns text that fits as a single line" do
      expect(text_painter.fit_lines("Short", cell_width, cell_height, 2, font_options)).to eq(["Short"])
    end

    it "limits the lines to the maximum and ellipsizes the last one" do
      lines = text_painter.fit_lines(long_text, cell_width, cell_height, 1, font_options)

      expect(lines.size).to eq(1)
      expect(lines.first).to end_with("...")
    end

    it "limits the lines to what fits into the height" do
      one_line_height = pdf.font.height_at(font_size) + 1

      expect(text_painter.fit_lines(long_text, cell_width, one_line_height, 2, font_options).size).to eq(1)
    end

    it "returns no lines for empty text" do
      expect(text_painter.fit_lines("", cell_width, cell_height, 2, font_options)).to eq([])
    end
  end

  describe "#lines_height" do
    it "is the line height times the number of lines" do
      expect(text_painter.lines_height(2, font_size)).to be_within(0.02).of(pdf.font.height_at(font_size) * 2)
    end
  end

  describe "#cap_height_ratio" do
    it "reads the cap height of a TrueType font" do
      ttf = pdf.font.ttf

      expect(text_painter.cap_height_ratio(pdf.font))
        .to eq(ttf.os2.cap_height.to_f / ttf.header.units_per_em)
    end

    it "falls back for fonts without TrueType metrics" do
      pdf.font("Helvetica")

      expect(text_painter.cap_height_ratio(pdf.font)).to eq(described_class::FALLBACK_CAP_HEIGHT_RATIO)
    end
  end

  describe "#font_metrics" do
    it "scales ascender and cap height with the size" do
      expect(text_painter.font_metrics(16)).to eq(text_painter.font_metrics(8).map { |value| value * 2 })
    end
  end

  describe "#paint_fitted_text" do
    it "centers a single line vertically in the cell" do
      paint_cell("Short")

      expect(baselines.size).to eq(1)
      expect(ink_center).to be_within(0.2).of(cell_center)
    end

    it "centers two lines vertically in the cell" do
      paint_cell("A much longer subject that needs two lines and then even more text so it gets cut off at the end")

      expect(baselines.size).to eq(2)
      expect(ink_center).to be_within(0.2).of(cell_center)
    end

    it "fills the last line up to the cell width, cutting within a word" do
      paint_cell(long_text)
      shown_so_far = "#{painted_strings.first} #{painted_strings.last.delete_suffix('...')}"

      expect(painted_strings.size).to eq(2)
      expect(painted_strings.last).to end_with("...")
      expect(long_text).to start_with(shown_so_far)
      expect(long_text[shown_so_far.length]).not_to eq(" ")
      expect(width_of(painted_strings.last)).to be > (cell_width - width_of("m"))
    end

    it "aligns horizontally" do
      paint_cell("Short", align: :center)

      expect(positions.first.first - pdf.bounds.absolute_left)
        .to be_within(0.5).of((cell_width - width_of("Short")) / 2)
    end

    it "paints nothing for empty text" do
      paint_cell("")

      expect(painted_strings).to be_empty
    end
  end

  describe "#formatted_text_box_measured" do
    it "returns the rendered height of the formatted text" do
      single = text_painter.formatted_text_box_measured([{ text: "Short" }], { width: cell_width, size: font_size })
      double = text_painter.formatted_text_box_measured([{ text: long_text }], { width: cell_width * 2, size: font_size })

      expect(double).to be > single
    end
  end

  describe "#draw_styled_text" do
    it "draws the text at the given position in the given color and restores the fill color" do
      text_painter.draw_styled_text("Styled", style.merge(at: [10, 50], color: "FF0000"))

      expect(painted_strings).to eq(["Styled"])
      expect(positions.first).to eq([pdf.bounds.absolute_left + 10, pdf.bounds.absolute_bottom + 50])
      expect(pdf.fill_color).to eq("000000")
    end
  end

  describe "#draw_text_left, #draw_text_centered, #draw_text_right" do
    let(:text_width) { width_of("Placed") }

    it "draws at the left edge and returns the width" do
      expect(text_painter.draw_text_left("Placed", style, 50)).to be_within(0.01).of(text_width)
      expect(positions.first.first).to eq(pdf.bounds.absolute_left)
    end

    it "draws centered and returns the position and width" do
      x_position, returned_width = text_painter.draw_text_centered("Placed", style, 50)

      expect(x_position).to be_within(0.01).of((pdf.bounds.width - text_width) / 2)
      expect(returned_width).to be_within(0.01).of(text_width)
      expect(positions.first.first).to be_within(0.01).of(pdf.bounds.absolute_left + x_position)
    end

    it "draws at the right edge and returns the width" do
      text_painter.draw_text_right("Placed", style, 50)

      expect(positions.first.first).to be_within(0.01).of(pdf.bounds.absolute_right - text_width)
    end
  end

  describe "#draw_text_multiline_part" do
    it "draws the line and returns its height" do
      height = text_painter.draw_text_multiline_part("Part", style, 0, 50)

      expect(painted_strings).to eq(["Part"])
      expect(height).to eq(text_painter.measure_text_height("Part", style))
    end
  end

  describe "multiline drawing" do
    let(:top) { 300 }
    let(:line_height) { text_painter.measure_text_height("Line", style) }

    it "draws header lines downwards from the top" do
      text_painter.draw_header_text_multilines(%w[First Second], 5, top, style)

      expect(painted_strings).to eq(%w[First Second])
      expect(positions.map(&:first).uniq).to eq([pdf.bounds.absolute_left + 5])
      expect(baselines.first - baselines.last).to be_within(0.01).of(line_height)
    end

    it "wraps and draws header text downwards from the top, left aligned" do
      text_painter.draw_header_text_multiline_left(text: long_text, text_style: style, available_width: cell_width,
                                                   top:, max_lines: 2)

      expect(painted_strings.size).to eq(2)
      expect(painted_strings.last).to end_with("...")
      expect(baselines.first).to be_within(0.01).of(pdf.bounds.absolute_bottom + top)
      expect(baselines.first).to be > baselines.last
    end

    it "wraps and draws footer text upwards from the bottom line, left aligned" do
      text_painter.draw_footer_text_multiline_left(text: long_text, text_style: style, available_width: cell_width,
                                                   top:, max_lines: 2)

      bottom_line = painted_strings[baselines.index(baselines.min)]

      expect(painted_strings.size).to eq(2)
      expect(baselines.min).to be_within(0.01).of(pdf.bounds.absolute_bottom + top)
      expect(bottom_line).to end_with("...")
    end

    it "wraps and draws centered text upwards from the bottom line" do
      text_painter.draw_text_multiline_center(text: long_text, text_style: style, left: 10,
                                              available_width: cell_width, top:, max_lines: 2)
      centers = painted_strings.zip(positions).map do |text, (x_position, _)|
        x_position - pdf.bounds.absolute_left + (width_of(text) / 2)
      end

      expect(painted_strings.size).to eq(2)
      expect(centers).to all(be_within(0.5).of(10 + (cell_width / 2)))
      expect(baselines.min).to be_within(0.01).of(pdf.bounds.absolute_bottom + top)
    end
  end
end
