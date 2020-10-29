# frozen_string_literal: true

# There are three ways to create a PDF Document in Prawn: creating a new
# <code>Prawn::Document</code> instance, or using the
# <code>Prawn::Document.generate</code> method with and without block arguments.
#
# The following snippet showcase each way by creating a simple document with
# some text drawn.
#
# When we instantiate the <code>Prawn::Document</code> object the actual pdf
# document will only be created after we call <code>render_file</code>.
#
# The generate method will render the actual pdf object after exiting the block.
# When we use it without a block argument the provided block is evaluated in the
# context of a newly created <code>Prawn::Document</code> instance. When we use
# it with a block argument a <code>Prawn::Document</code> instance is created
# and passed to the block.
#
# The generate method without block arguments requires
# less typing and defines and renders the pdf document in one shot.
# Almost all of the examples are coded this way.

require_relative '../example_helper'

# Assignment
pdf = Prawn::Document.new
pdf.text 'Hello World'
pdf.render_file 'assignment.pdf'

# Implicit Block
Prawn::Document.generate('implicit.pdf') do
  text 'Hello World'
end

# Explicit Block
Prawn::Document.generate('explicit.pdf') do |pdf|
  pdf.text 'Hello World'
end
