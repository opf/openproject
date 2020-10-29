# frozen_string_literal: true

# The <code>:callback</code> option is also available for the formatted text
# methods.
#
# This option accepts an object (or array of objects) on which two methods
# will be called if defined: <code>render_behind</code> and
# <code>render_in_front</code>. They are called before and after rendering the
# text fragment and are passed the fragment as an argument.
#
# This example defines two new callback classes and provide callback objects
# for the formatted_text

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  class HighlightCallback
    def initialize(options)
      @color = options[:color]
      @document = options[:document]
    end

    def render_behind(fragment)
      original_color = @document.fill_color
      @document.fill_color = @color
      @document.fill_rectangle(
        fragment.top_left,
        fragment.width,
        fragment.height
      )
      @document.fill_color = original_color
    end
  end

  class ConnectedBorderCallback
    def initialize(options)
      @radius = options[:radius]
      @document = options[:document]
    end

    def render_in_front(fragment)
      @document.stroke_polygon(
        fragment.top_left, fragment.top_right,
        fragment.bottom_right, fragment.bottom_left
      )

      @document.fill_circle(fragment.top_left,     @radius)
      @document.fill_circle(fragment.top_right,    @radius)
      @document.fill_circle(fragment.bottom_right, @radius)
      @document.fill_circle(fragment.bottom_left,  @radius)
    end
  end

  highlight = HighlightCallback.new(color: 'ffff00', document: self)
  border = ConnectedBorderCallback.new(radius: 2.5, document: self)

  formatted_text [
    { text: 'hello', callback: highlight },
    { text: '     ' },
    { text: 'world', callback: border },
    { text: '     ' },
    { text: 'hello world', callback: [highlight, border] }
  ], size: 20
end
