# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text do
  let(:pdf) { create_pdf }

  describe '#formatted_text' do
    it 'draws text' do
      string = 'hello world'
      format_array = [text: string]
      pdf.formatted_text(format_array)
      # grab the text from the rendered PDF and ensure it matches
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq(string)
    end
  end

  describe '#text with inline styling' do
    it 'automatically moves to a new page if the tallest fragment' \
      " on the next line won't fit in the available space" do
      pdf.move_cursor_to(pdf.font.height)
      formatted = "this contains <font size='24'>sized</font> text"
      pdf.text(formatted, inline_format: true)
      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(2)
    end

    it 'embeds links as literal strings' do
      pdf.text "<link href='http://wiki.github.com/sandal/prawn/'>wiki</link>",
        inline_format: true
      expect(pdf.render).to match(%r{/URI\s+\(http://wiki\.github\.com})
    end
  end
end
