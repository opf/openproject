# frozen_string_literal: true

# font.rb : The Prawn font class
#
# Copyright May 2008, Gregory Brown / James Healy. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
require_relative 'font_metric_cache'

module Prawn
  class Document
    # @group Stable API

    # Without arguments, this returns the currently selected font. Otherwise,
    # it sets the current font. When a block is used, the font is applied
    # transactionally and is rolled back when the block exits.
    #
    #   Prawn::Document.generate("font.pdf") do
    #     text "Default font is Helvetica"
    #
    #     font "Times-Roman"
    #     text "Now using Times-Roman"
    #
    #     font("DejaVuSans.ttf") do
    #       text "Using TTF font from file DejaVuSans.ttf"
    #       font "Courier", :style => :bold
    #       text "You see this in bold Courier"
    #     end
    #
    #     text "Times-Roman, again"
    #   end
    #
    # The :name parameter must be a string. It can be one of the 14 built-in
    # fonts supported by PDF, or the location of a TTF file. The
    # Fonts::AFM::BUILT_INS array specifies the valid built in font values.
    #
    # If a ttf font is specified, the glyphs necessary to render your document
    # will be embedded in the rendered PDF. This should be your preferred option
    # in most cases. It will increase the size of the resulting file, but also
    # make it more portable.
    #
    # The options parameter is an optional hash providing size and style. To use
    # the :style option you need to map those font styles to their respective
    # font files.
    # See font_families for more information.
    #
    def font(name = nil, options = {})
      return((defined?(@font) && @font) || font('Helvetica')) if name.nil?

      if state.pages.empty? && !state.page.in_stamp_stream?
        raise Prawn::Errors::NotOnPage
      end

      new_font = find_font(name.to_s, options)

      if block_given?
        save_font do
          set_font(new_font, options[:size])
          yield
        end
      else
        set_font(new_font, options[:size])
      end

      @font
    end

    # @method font_size(points=nil)
    #
    # When called with no argument, returns the current font size.
    #
    # When called with a single argument but no block, sets the current font
    # size.  When a block is used, the font size is applied transactionally and
    # is rolled back when the block exits.  You may still change the font size
    # within a transactional block for individual text segments, or nested calls
    # to font_size.
    #
    #   Prawn::Document.generate("font_size.pdf") do
    #     font_size 16
    #     text "At size 16"
    #
    #     font_size(10) do
    #       text "At size 10"
    #       text "At size 6", :size => 6
    #       text "At size 10"
    #     end
    #
    #     text "At size 16"
    #   end
    #
    # When called without an argument, this method returns the current font
    # size.
    #
    def font_size(points = nil)
      return @font_size unless points

      size_before_yield = @font_size
      @font_size = points
      block_given? ? yield : return
      @font_size = size_before_yield
    end

    # Sets the font size
    def font_size=(size)
      font_size(size)
    end

    # Returns the width of the given string using the given font. If :size is
    # not specified as one of the options, the string is measured using the
    # current font size. You can also pass :kerning as an option to indicate
    # whether kerning should be used when measuring the width (defaults to
    # +false+).
    #
    # Note that the string _must_ be encoded properly for the font being used.
    # For AFM fonts, this is WinAnsi. For TTF, make sure the font is encoded as
    # UTF-8. You can use the Font#normalize_encoding method to make sure strings
    # are in an encoding appropriate for the current font.
    #--
    # For the record, this method used to be a method of Font (and still
    # delegates to width computations on Font). However, having the primary
    # interface for calculating string widths exist on Font made it tricky to
    # write extensions for Prawn in which widths are computed differently (e.g.,
    # taking formatting tags into account, or the like).
    #
    # By putting width_of here, on Document itself, extensions may easily
    # override it and redefine the width calculation behavior.
    #++
    def width_of(string, options = {})
      if options.key? :inline_format
        p = options[:inline_format]
        p = [] unless p.is_a?(Array)

        # Build up an Arranger with the entire string on one line, finalize it,
        # and find its width.
        arranger = Prawn::Text::Formatted::Arranger.new(self, options)
        arranger.consumed = text_formatter.format(string, *p)
        arranger.finalize_line

        arranger.line_width
      else
        width_of_string(string, options)
      end
    end

    # Hash that maps font family names to their styled individual font names.
    #
    # To add support for another font family, append to this hash, e.g:
    #
    #   pdf.font_families.update(
    #    "MyTrueTypeFamily" => { :bold        => "foo-bold.ttf",
    #                            :italic      => "foo-italic.ttf",
    #                            :bold_italic => "foo-bold-italic.ttf",
    #                            :normal      => "foo.ttf" })
    #
    # This will then allow you to use the fonts like so:
    #
    #   pdf.font("MyTrueTypeFamily", :style => :bold)
    #   pdf.text "Some bold text"
    #   pdf.font("MyTrueTypeFamily")
    #   pdf.text "Some normal text"
    #
    # This assumes that you have appropriate TTF fonts for each style you
    # wish to support.
    #
    # By default the styles :bold, :italic, :bold_italic, and :normal are
    # defined for fonts "Courier", "Times-Roman" and "Helvetica". When
    # defining your own font families, you can map any or all of these
    # styles to whatever font files you'd like.
    #
    def font_families
      @font_families ||= {}.merge!(
        'Courier' => {
          bold: 'Courier-Bold',
          italic: 'Courier-Oblique',
          bold_italic: 'Courier-BoldOblique',
          normal: 'Courier'
        },

        'Times-Roman' => {
          bold: 'Times-Bold',
          italic: 'Times-Italic',
          bold_italic: 'Times-BoldItalic',
          normal: 'Times-Roman'
        },

        'Helvetica' => {
          bold: 'Helvetica-Bold',
          italic: 'Helvetica-Oblique',
          bold_italic: 'Helvetica-BoldOblique',
          normal: 'Helvetica'
        }
      )
    end

    # @group Experimental API

    # Sets the font directly, given an actual Font object
    # and size.
    #
    def set_font(font, size = nil) # :nodoc:
      @font = font
      @font_size = size if size
    end

    # Saves the current font, and then yields. When the block
    # finishes, the original font is restored.
    #
    def save_font
      @font ||= find_font('Helvetica')
      original_font = @font
      original_size = @font_size

      yield
    ensure
      set_font(original_font, original_size) if original_font
    end

    # Looks up the given font using the given criteria. Once a font has been
    # found by that matches the criteria, it will be cached to subsequent
    # lookups for that font will return the same object.
    # --
    # Challenges involved: the name alone is not sufficient to uniquely identify
    # a font (think dfont suitcases that can hold multiple different fonts in a
    # single file). Thus, the :name key is included in the cache key.
    #
    # It is further complicated, however, since fonts in some formats (like the
    # dfont suitcases) can be identified either by numeric index, OR by their
    # name within the suitcase, and both should hash to the same font object (to
    # avoid the font being embedded multiple times). This is not yet
    # implemented, which means if someone selects a font both by name, and by
    # index, the font will be embedded twice. Since we do font subsetting, this
    # double embedding won't be catastrophic, just annoying.
    # ++
    #
    # @private
    def find_font(name, options = {}) #:nodoc:
      if font_families.key?(name)
        family = name
        name = font_families[name][options[:style] || :normal]
        if name.is_a?(::Hash)
          options = options.merge(name)
          name = options[:file]
        end
      end
      key = "#{name}:#{options[:font] || 0}"

      if name.is_a? Prawn::Font
        font_registry[key] = name
      else
        font_registry[key] ||=
          Font.load(self, name, options.merge(family: family))
      end
    end

    # Hash of Font objects keyed by names
    #
    def font_registry #:nodoc:
      @font_registry ||= {}
    end

    private

    def width_of_inline_formatted_string(string, options = {})
      # Build up an Arranger with the entire string on one line, finalize it,
      # and find its width.
      arranger = Prawn::Text::Formatted::Arranger.new(self, options)
      arranger.consumed = Text::Formatted::Parser.format(string)
      arranger.finalize_line

      arranger.line_width
    end

    def width_of_string(string, options = {})
      font_metric_cache.width_of(string, options)
    end
  end

  # Provides font information and helper functions.
  #
  class Font
    require_relative 'fonts/afm'
    require_relative 'fonts/ttf'
    require_relative 'fonts/dfont'
    require_relative 'fonts/otf'
    require_relative 'fonts/ttc'

    # @deprecated
    AFM = Fonts::AFM
    TTF = Fonts::TTF
    DFont = Fonts::DFont
    TTC = Fonts::TTC

    # The current font name
    attr_reader :name

    # The current font family
    attr_reader :family

    # The options hash used to initialize the font
    attr_reader :options

    # Shortcut interface for constructing a font object.  Filenames of the form
    # *.ttf will call Fonts::TTF.new, *.dfont Fonts::DFont.new, *.ttc goes to
    # Fonts::TTC.new, and anything else will be passed through to
    # Fonts::AFM.new()
    def self.load(document, src, options = {})
      case font_format(src, options)
      when 'ttf' then TTF.new(document, src, options)
      when 'otf' then Fonts::OTF.new(document, src, options)
      when 'dfont' then DFont.new(document, src, options)
      when 'ttc' then TTC.new(document, src, options)
      else AFM.new(document, src, options)
      end
    end

    def self.font_format(src, options)
      return options.fetch(:format, 'ttf') if src.respond_to? :read

      case src.to_s
      when /\.ttf$/i   then 'ttf'
      when /\.otf$/i   then 'otf'
      when /\.dfont$/i then 'dfont'
      when /\.ttc$/i   then 'ttc'
      else 'afm'
      end
    end

    def initialize(document, name, options = {}) #:nodoc:
      @document = document
      @name = name
      @options = options

      @family = options[:family]

      @identifier = generate_unique_id

      @references = {}
    end

    # The size of the font ascender in PDF points
    #
    def ascender
      @ascender / 1000.0 * size
    end

    # The size of the font descender in PDF points
    #
    def descender
      -@descender / 1000.0 * size
    end

    # The size of the recommended gap between lines of text in PDF points
    #
    def line_gap
      @line_gap / 1000.0 * size
    end

    # Normalizes the encoding of the string to an encoding supported by the
    # font. The string is expected to be UTF-8 going in. It will be re-encoded
    # and the new string will be returned. For an in-place (destructive)
    # version, see normalize_encoding!.
    def normalize_encoding(_string)
      raise NotImplementedError,
        'subclasses of Prawn::Font must implement #normalize_encoding'
    end

    # Destructive version of normalize_encoding; normalizes the encoding of a
    # string in place.
    #
    # @deprecated
    def normalize_encoding!(str)
      warn 'Font#normalize_encoding! is deprecated. ' \
        'Please use non-mutating version Font#normalize_encoding instead.'
      str.dup.replace(normalize_encoding(str))
    end

    # Gets height of current font in PDF points at the given font size
    #
    def height_at(size)
      @normalized_height ||= (@ascender - @descender + @line_gap) / 1000.0
      @normalized_height * size
    end

    # Gets height of current font in PDF points at current font size
    #
    def height
      height_at(size)
    end

    # Registers the given subset of the current font with the current PDF
    # page. This is safe to call multiple times for a given font and subset,
    # as it will only add the font the first time it is called.
    #
    def add_to_current_page(subset)
      @references[subset] ||= register(subset)
      @document.state.page.fonts.merge!(
        identifier_for(subset) => @references[subset]
      )
    end

    def identifier_for(subset) #:nodoc:
      "#{@identifier}.#{subset}".to_sym
    end

    def inspect #:nodoc:
      "#{self.class.name}< #{name}: #{size} >"
    end

    # Return a hash (as in Object#hash) for the font based on the output of
    # #inspect. This is required since font objects are used as keys in hashes
    # that cache certain values (See
    # Prawn::Table::Text#styled_with_of_single_character)
    #
    def hash #:nodoc:
      [self.class, name, family, size].hash
    end

    # Compliments the #hash implementation above
    #
    def eql?(other) #:nodoc:
      self.class == other.class && name == other.name &&
        family == other.family && size == other.send(:size)
    end

    private

    # generate a font identifier that hasn't been used on the current page yet
    #
    def generate_unique_id
      key = nil
      font_count = @document.font_registry.size + 1
      loop do
        key = :"F#{font_count}"
        break if key_is_unique?(key)

        font_count += 1
      end
      key
    end

    def key_is_unique?(test_key)
      @document.state.page.fonts.keys.none? do |key|
        key.to_s.start_with?("#{test_key}.")
      end
    end

    def size
      @document.font_size
    end
  end
end
