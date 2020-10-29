# frozen_string_literal: true

# Most font families come with some styles other than normal. Most common are
# <code>bold</code>, <code>italic</code> and <code>bold_italic</code>.
#
# The style can be set the using the <code>:style</code> option, with either the
# <code>font</code> method which will set the font and style for rest of the
# document, or with the inline text methods.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  %w[Courier Helvetica Times-Roman].each do |example_font|
    move_down 20

    %i[bold bold_italic italic normal].each do |style|
      font example_font, style: style
      text "I'm writing in #{example_font} (#{style})"
    end
  end
end
