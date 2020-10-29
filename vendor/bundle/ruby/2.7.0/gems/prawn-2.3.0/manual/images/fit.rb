# frozen_string_literal: true

# <code>:fit</code> option is useful when you want the image to have the
# maximum size within a container preserving the aspect ratio without
# overlapping.
#
# Just provide the container width and height pair.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  size = 300

  text 'Using the fit option'
  bounding_box([0, cursor], width: size, height: size) do
    image "#{Prawn::DATADIR}/images/pigs.jpg", fit: [size, size]
    stroke_bounds
  end
end
