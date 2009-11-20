module CodeRay
module Encoders

  class HTML
    class CSS

      attr :stylesheet

      def CSS.load_stylesheet style = nil
        CodeRay::Styles[style]
      end

      def initialize style = :default
        @classes = Hash.new
        style = CSS.load_stylesheet style
        @stylesheet = [
          style::CSS_MAIN_STYLES,
          style::TOKEN_COLORS.gsub(/^(?!$)/, '.CodeRay ')
        ].join("\n")
        parse style::TOKEN_COLORS
      end

      def [] *styles
        cl = @classes[styles.first]
        return '' unless cl
        style = ''
        1.upto(styles.size) do |offset|
          break if style = cl[styles[offset .. -1]]
        end
        raise 'Style not found: %p' % [styles] if $DEBUG and style.empty?
        return style
      end

    private

      CSS_CLASS_PATTERN = /
        ( (?:                # $1 = classes
          \s* \. [-\w]+
        )+ )
        \s* \{ \s*
        ( [^\}]+ )?          # $2 = style
        \s* \} \s*
      |
        ( . )                # $3 = error
      /mx
      def parse stylesheet
        stylesheet.scan CSS_CLASS_PATTERN do |classes, style, error|
          raise "CSS parse error: '#{error.inspect}' not recognized" if error
          styles = classes.scan(/[-\w]+/)
          cl = styles.pop
          @classes[cl] ||= Hash.new
          @classes[cl][styles] = style.to_s.strip
        end
      end

    end
  end

end
end

if $0 == __FILE__
  require 'pp'
  pp CodeRay::Encoders::HTML::CSS.new
end
