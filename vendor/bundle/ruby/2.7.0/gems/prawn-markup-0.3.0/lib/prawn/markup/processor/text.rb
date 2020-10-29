# frozen_string_literal: true

module Prawn
  module Markup
    module Processor::Text
      def self.prepended(base)
        base.known_elements.push(
          'a', 'b', 'strong', 'i', 'em', 'u', 'strikethrough', 'strike', 's', 'del',
          'sub', 'sup'
        )
      end

      def start_a
        append_text("<link href=\"#{current_attrs['href']}\">")
      end
      alias start_link start_a

      def end_a
        append_text('</link>')
      end
      alias end_link end_a

      def start_b
        append_text('<b>')
      end
      alias start_strong start_b

      def end_b
        append_text('</b>')
      end
      alias end_strong end_b

      def start_i
        append_text('<i>')
      end
      alias start_em start_i

      def end_i
        append_text('</i>')
      end
      alias end_em end_i

      def start_u
        append_text('<u>')
      end

      def end_u
        append_text('</u>')
      end

      def start_strikethrough
        append_text('<strikethrough>')
      end
      alias start_s start_strikethrough
      alias start_strike start_strikethrough
      alias start_del start_strikethrough

      def end_strikethrough
        append_text('</strikethrough>')
      end
      alias end_s end_strikethrough
      alias end_strike end_strikethrough
      alias end_del end_strikethrough

      def start_sub
        append_text('<sub>')
      end

      def end_sub
        append_text('</sub>')
      end

      def start_sup
        append_text('<sup>')
      end

      def end_sup
        append_text('</sup>')
      end

    end
  end
end
