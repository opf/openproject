module TaskboardCard
  class CardArea
    unloadable

    def self.pref_size_percent
      raise NotImplementedError.new('Subclasses need to implement this methods')
    end

    def self.text_box(pdf, text, options)
      options = adapted_text_box_options(pdf, text, options)
      text = abbreviate_text(pdf, text, options)

      pdf.text_box(text, options)

      Box.new(options[:at][0], options[:at][1], options[:width], options[:height] + options[:padding_bottom])
    end

    def self.render_bounding_box(pdf, options)
      opts = { :width => pdf.bounds.width }
      offset = options[:at] || [0, pdf.bounds.height]

      pdf.bounding_box(offset, opts.merge(options)) do

        pdf.stroke_bounds if options[:border]

        if options[:margin]
          pdf.bounding_box([options[:margin], pdf.bounds.height - options[:margin]],
                          :width => pdf.bounds.width - (2 * options[:margin]),
                          :height => pdf.bounds.height - (2 * options[:margin])) do

            yield
          end
        else
          yield
        end
      end
    end

    def self.min_size
      [0, 0]
    end

    def self.margin
      0
    end

    def self.render(pdf, issue, offset)
      raise NotImplementedError.new('Subclasses need to implement this methods')
    end

    def self.strip_tags(string)
      ActionController::Base.helpers.strip_tags(string)
    end

    private

    def self.adapted_text_box_options(pdf, text, options)
      align = options.delete(:align)
      if align == :right
        options[:width] = pdf.width_of(text, options)
        options[:at][0] = pdf.bounds.width - options[:width]
      end

      opts = {:width => pdf.bounds.width,
              :padding_bottom => 10,
              :document => pdf}

      opts.merge(options)
    end

    def self.abbreviate_text(pdf, text, options)
      text_box = Prawn::Text::Box.new(text, options)
      left_over = text_box.render(:dry_run => true)

      # be sure to do length arithmetics on chars, not bytes!
      left_over = left_over.mb_chars
      text      = text.to_s.mb_chars

      left_over.size > 0 ? text[0 ... -(left_over.size + 5)] + "[...]" : text
    rescue Prawn::Errors::CannotFit
      ''
    end
  end
end
