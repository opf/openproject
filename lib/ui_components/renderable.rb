module UiComponents
  module Renderable
    module InstanceMethods
      attr_accessor :strategy

      def render!
        if @strategy.nil?
          content_tag :div
        else
          @strategy.call
        end
      end
    end

    def self.included(receiver)
      receiver.send :include, InstanceMethods
      receiver.send :include, ActionView::Helpers
    end
  end
end
