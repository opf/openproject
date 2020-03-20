# As the successor to the MyProjectPage Plugin and possibly inheriting the data from it,
# we Overview needs to convert textile in custom_text widgets. The converter can be executed after
# the migration.

module Overviews::Patches
  module TextileConverterPatch
    extend ActiveSupport::Concern

    included do
      prepend(Patch)
    end

    module Patch
      def convert_custom_text_widgets
        # If the table does not exist yet, there is nothing to convert
        return unless Grids::Overview.table_exists?

        print Grids::Overview.name

        text_widgets_to_convert
          .in_batches(of: 200) do |widget|
            widget.options['text'] = convert_textile_to_markdown(widget.options['text']) if widget.options['text']
            widget.save

            print ' .'
          end

        print 'done'
      end

      def text_widgets_to_convert
        Grids::Widget
          .includes(:grid)
          .where(grids: { type: 'Grids::Overview' })
          .where(identifier: 'custom_text')
      end

      def converters
        super + [method(:convert_custom_text_widgets)]
      end
    end
  end
end
