require 'forwardable'

module PDF
  class Inspector
    class Page < Inspector
      extend Forwardable

      attr_reader :pages

      def_delegators :@state, :set_text_font_and_size

      def initialize
        @pages = []
      end

      def page=(page)
        @pages << { size: page.attributes[:MediaBox][-2..-1], strings: [] }
        @state = PDF::Reader::PageState.new(page)
      end

      def show_text(*params)
        params.each do |param|
          @pages.last[:strings] << @state.current_font.to_utf8(param)
        end
      end

      def show_text_with_positioning(*params)
        # ignore kerning information
        show_text params[0].reject { |e|
          e.is_a? Numeric
        }.join
      end
    end
  end
end
