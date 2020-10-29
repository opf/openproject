# frozen_string_literal: true

# Soft masks are used for more complex alpha channel manipulations. You can use
# arbitrary drawing functions for creation of soft masks. The resulting alpha
# channel is made of greyscale version of the drawing (luminosity channel to be
# precise). So while you can use any combination of colors for soft masks it's
# easier to use greyscales. Black will result in full transparency and white
# will make region fully opaque.
#
# Soft mask is a part of page graphic state. So if you want to apply soft mask
# only to a part of page you need to enclose drawing instructions in
# <code>save_graphics_state</code> block.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  save_graphics_state do
    soft_mask do
      0.upto 15 do |i|
        fill_color 0, 0, 0, 100.0 / 16.0 * (15 - i)
        fill_circle [75 + i * 25, 100], 60
      end
    end

    fill_color '009ddc'
    fill_rectangle [0, 60], 600, 20

    fill_color '963d97'
    fill_rectangle [0, 80], 600, 20

    fill_color 'e03a3e'
    fill_rectangle [0, 100], 600, 20

    fill_color 'f5821f'
    fill_rectangle [0, 120], 600, 20

    fill_color 'fdb827'
    fill_rectangle [0, 140], 600, 20

    fill_color '61bb46'
    fill_rectangle [0, 160], 600, 20
  end
end
