# encoding: utf-8
#
# Prawn can insert images into a table. Just pass a hash into
# <code>table()</code> with an <code>:image</code> key pointing to the image.
#
# You can pass the <code>:scale</code>, <code>:fit</code>,
# <code>:position</code>, and <code>:vposition</code> arguments in alongside
# <code>:image</code>; these will function just as in <code>image()</code>.
#
# The <code>:image_width</code> and <code>:image_height</code> arguments set
# the width/height of the image within the cell, as opposed to the
# <code>:width</code> and <code>:height</code> arguments, which set the table
# cell's dimensions.
#
require File.expand_path(File.join(File.dirname(__FILE__),
                                   %w[.. example_helper]))

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  image = "#{Prawn::DATADIR}/images/prawn.png"

  table [
    ["Standard image cell",   {:image => image}],
    [":scale => 0.5",         {:image => image, :scale => 0.5}],
    [":fit => [100, 200]",    {:image => image, :fit => [100, 200]}],
    [":image_height => 50,
      :image_width => 100",   {:image => image, :image_height => 50,
                                                :image_width  => 100}],
    [":position => :center",  {:image => image, :position  => :center}],
    [":vposition => :center", {:image => image, :vposition => :center,
                                                :height => 200}]
  ], :width => bounds.width
end
