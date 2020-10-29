# frozen_string_literal: true

# We normally write our documents from top to bottom and it is no different with
# Prawn. Even if the origin is on the bottom left corner we still fill the page
# from the top to the bottom. In other words the cursor for inserting content
# starts on the top of the page.
#
# Most of the functions that insert content on the page will start at the
# current cursor position and proceed to the bottom of the page.
#
# The following snippet shows how the cursor behaves when we add some text to
# the page and demonstrates some of the helpers to manage the cursor position.
# The <code>cursor</code> method returns the current cursor position.

require_relative '../example_helper'

filename = File.basename(__FILE__).gsub('.rb', '.pdf')
Prawn::ManualBuilder::Example.generate(filename) do
  stroke_axis

  text "the cursor is here: #{cursor}"
  text "now it is here: #{cursor}"

  move_down 200
  text "on the first move the cursor went down to: #{cursor}"

  move_up 100
  text "on the second move the cursor went up to: #{cursor}"

  move_cursor_to 50
  text "on the last move the cursor went directly to: #{cursor}"
end
