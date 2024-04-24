module OpenProject
  module Deprecated
    # @logical_path OpenProject/deprecated
    class TooltipPreview < Lookbook::Preview
      # These can contain simple texts.
      #
      # Attention:
      # - They are not suitable for HTML within the Tooltip.
      # - Also, if the are already :before or :after CSS rules for the decorated element,
      # things will break as these rules will get overwritten.
      def default; end

      def forms; end
    end
  end
end
