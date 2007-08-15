require "set"

module CodeRay
module Encoders

  # = HTML Encoder
  #
  # This is CodeRay's most important highlighter:
  # It provides save, fast XHTML generation and CSS support.
  #
  # == Usage
  #
  #  require 'coderay'
  #  puts CodeRay.scan('Some /code/', :ruby).html  #-> a HTML page
  #  puts CodeRay.scan('Some /code/', :ruby).html(:wrap => :span)
  #  #-> <span class="CodeRay"><span class="co">Some</span> /code/</span>
  #  puts CodeRay.scan('Some /code/', :ruby).span  #-> the same
  #  
  #  puts CodeRay.scan('Some code', :ruby).html(
  #    :wrap => nil,
  #    :line_numbers => :inline,
  #    :css => :style
  #  )
  #  #-> <span class="no">1</span>  <span style="color:#036; font-weight:bold;">Some</span> code
  #
  # == Options
  #
  # === :tab_width
  # Convert \t characters to +n+ spaces (a number.)
  # Default: 8
  #
  # === :css
  # How to include the styles; can be :class or :style.
  #
  # Default: :class
  #
  # === :wrap
  # Wrap in :page, :div, :span or nil.
  #
  # You can also use Encoders::Div and Encoders::Span.
  #
  # Default: nil
  #
  # === :line_numbers
  # Include line numbers in :table, :inline, :list or nil (no line numbers)
  #
  # Default: nil
  #
  # === :line_number_start
  # Where to start with line number counting.
  #
  # Default: 1
  #
  # === :bold_every
  # Make every +n+-th number appear bold.
  #
  # Default: 10
  #
  # === :hint
  # Include some information into the output using the title attribute.
  # Can be :info (show token type on mouse-over), :info_long (with full path)
  # or :debug (via inspect).
  #
  # Default: false
  class HTML < Encoder

    include Streamable
    register_for :html

    FILE_EXTENSION = 'html'

    DEFAULT_OPTIONS = {
      :tab_width => 8,

      :level => :xhtml,
      :css => :class,

      :style => :cycnus,

      :wrap => nil,

      :line_numbers => nil,
      :line_number_start => 1,
      :bold_every => 10,

      :hint => false,
    }

    helper :output, :css

    attr_reader :css

  protected

    HTML_ESCAPE = {  #:nodoc:
      '&' => '&amp;',
      '"' => '&quot;',
      '>' => '&gt;',
      '<' => '&lt;',
    }

    # This was to prevent illegal HTML.
    # Strange chars should still be avoided in codes.
    evil_chars = Array(0x00...0x20) - [?\n, ?\t, ?\s]
    evil_chars.each { |i| HTML_ESCAPE[i.chr] = ' ' }
    #ansi_chars = Array(0x7f..0xff)
    #ansi_chars.each { |i| HTML_ESCAPE[i.chr] = '&#%d;' % i }
    # \x9 (\t) and \xA (\n) not included
    #HTML_ESCAPE_PATTERN = /[\t&"><\0-\x8\xB-\x1f\x7f-\xff]/
    HTML_ESCAPE_PATTERN = /[\t"&><\0-\x8\xB-\x1f]/

    TOKEN_KIND_TO_INFO = Hash.new { |h, kind|
      h[kind] =
        case kind
        when :pre_constant
          'Predefined constant'
        else
          kind.to_s.gsub(/_/, ' ').gsub(/\b\w/) { $&.capitalize }
        end
    }

    TRANSPARENT_TOKEN_KINDS = [
      :delimiter, :modifier, :content, :escape, :inline_delimiter,
    ].to_set

    # Generate a hint about the given +classes+ in a +hint+ style.
    #
    # +hint+ may be :info, :info_long or :debug.
    def self.token_path_to_hint hint, classes
      title =
        case hint
        when :info
          TOKEN_KIND_TO_INFO[classes.first]
        when :info_long
          classes.reverse.map { |kind| TOKEN_KIND_TO_INFO[kind] }.join('/')
        when :debug
          classes.inspect
        end
      " title=\"#{title}\""
    end

    def setup options
      super

      @HTML_ESCAPE = HTML_ESCAPE.dup
      @HTML_ESCAPE["\t"] = ' ' * options[:tab_width]

      @opened = [nil]
      @css = CSS.new options[:style]

      hint = options[:hint]
      if hint and not [:debug, :info, :info_long].include? hint
        raise ArgumentError, "Unknown value %p for :hint; \
          expected :info, :debug, false, or nil." % hint
      end

      case options[:css]

      when :class
        @css_style = Hash.new do |h, k|
          c = Tokens::ClassOfKind[k.first]
          if c == :NO_HIGHLIGHT and not hint
            h[k.dup] = false
          else
            title = if hint
              HTML.token_path_to_hint(hint, k[1..-1] << k.first)
            else
              ''
            end
            if c == :NO_HIGHLIGHT
              h[k.dup] = '<span%s>' % [title]
            else
              h[k.dup] = '<span%s class="%s">' % [title, c]
            end
          end
        end

      when :style
        @css_style = Hash.new do |h, k|
          if k.is_a? ::Array
            styles = k.dup
          else
            styles = [k]
          end
          type = styles.first
          classes = styles.map { |c| Tokens::ClassOfKind[c] }
          if classes.first == :NO_HIGHLIGHT and not hint
            h[k] = false
          else
            styles.shift if TRANSPARENT_TOKEN_KINDS.include? styles.first
            title = HTML.token_path_to_hint hint, styles
            style = @css[*classes]
            h[k] =
              if style
                '<span%s style="%s">' % [title, style]
              else
                false
              end
          end
        end

      else
        raise ArgumentError, "Unknown value %p for :css." % options[:css]

      end
    end

    def finish options
      not_needed = @opened.shift
      @out << '</span>' * @opened.size
      unless @opened.empty?
        warn '%d tokens still open: %p' % [@opened.size, @opened]
      end

      @out.extend Output
      @out.css = @css
      @out.numerize! options[:line_numbers], options
      @out.wrap! options[:wrap]

      super
    end

    def token text, type
      if text.is_a? ::String
        if text =~ /#{HTML_ESCAPE_PATTERN}/o
          text = text.gsub(/#{HTML_ESCAPE_PATTERN}/o) { |m| @HTML_ESCAPE[m] }
        end
        @opened[0] = type
        if style = @css_style[@opened]
          @out << style << text << '</span>'
        else
          @out << text
        end
      else
        case text
        when :open
          @opened[0] = type
          @out << (@css_style[@opened] || '<span>')
          @opened << type
        when :close
          if @opened.empty?
            # nothing to close
          else
            if $DEBUG and (@opened.size == 1 or @opened.last != type)
              raise 'Malformed token stream: Trying to close a token (%p) \
                that is not open. Open are: %p.' % [type, @opened[1..-1]]
            end
            @out << '</span>'
            @opened.pop
          end
        when nil
          raise 'Token with nil as text was given: %p' % [[text, type]]
        else
          raise 'unknown token kind: %p' % text
        end
      end
    end

  end

end
end
