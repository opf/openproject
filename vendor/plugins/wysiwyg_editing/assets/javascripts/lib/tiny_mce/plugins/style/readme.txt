Edit CSS Style plug-in notes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Unlike WYSIWYG editor functionality that operates only on the selected text,
typically by inserting new HTML elements with the specified styles.
This plug-in operates on the HTML blocks surrounding the selected text.
No new HTML elements are created.

This plug-in only operates on the surrounding blocks and not the nearest
parent node.  This means that if a block encapsulates a node,
e.g <p><span>text</span></p>, then only the styles in the block are
recognized, not those in the span.

When selecting text that includes multiple blocks at the same level (peers),
this plug-in accumulates the specified styles in all of the surrounding blocks
and populates the dialogue checkboxes accordingly.  There is no differentiation
between styles set in all the blocks versus styles set in some of the blocks.

When the [Update] or [Apply] buttons are pressed, the styles selected in the
checkboxes are applied to all blocks that surround the selected text.
