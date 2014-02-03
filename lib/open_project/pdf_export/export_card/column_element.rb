module OpenProject::PdfExport::ExportCard
  class ColumnElement
    def initialize(pdf, property_name, config, orientation, work_package)
      @pdf = pdf
      @property_name = property_name
      @config = config
      @orientation = orientation
      @work_package = work_package
    end

    def draw
      # Get value from model
      value = @work_package.send(@property_name) if @work_package.respond_to?(@property_name) else ""

      if value.is_a?(Array)
        value = value.map{|c| c.to_s }.join("\n")
      end
      draw_value(value)
    end

    def draw_value(value)
      # Font size
      if @config['font_size']
        # Specific size given
        overflow = :truncate
        font_size = Integer(@config['font_size'])

      elsif @config['min_font_size']
        # Range given
        overflow = :shrink_to_fit
        min_font_size = Integer(@config['min_font_size'])
        font_size = if @config['max_font_size']
                      Integer(@config['max_font_size'])
                    else
                      min_font_size
                    end
      else
        # Default
        font_size = 12
        overflow = :truncate
      end

      font_style = (@config['font_style'] or "normal").to_sym
      text_align = (@config['text_align'] or "left").to_sym

      # Label and text
      has_label = @config['has_label']
      indented = @config['indented']
      value = value.to_s if !value.is_a?(String)
      label_text = if has_label
                     "#{@work_package.class.human_attribute_name(@property_name)}: "
                   else
                     ""
                   end

      if has_label && indented
        width_ratio = 0.2 # Note: I don't think it's worth having this in the config

        # Label Textbox
        offset = [@orientation[:x_offset], @orientation[:height] - (@orientation[:text_padding] / 2)]
        box = @pdf.text_box(label_text,
          {:height => @orientation[:height],
           :width => @orientation[:width] * width_ratio,
           :at => offset,
           :style => :bold,
           :overflow => overflow,
           :size => font_size,
           :min_font_size => min_font_size,
           :align => :left})

        # Content Textbox
        offset = [@orientation[:x_offset] + (@orientation[:width] * width_ratio), @orientation[:height] - (@orientation[:text_padding] / 2)]
        box = @pdf.text_box(value,
          {:height => @orientation[:height],
           :width => @orientation[:width] * (1 - width_ratio),
           :at => offset,
           :style => font_style,
           :overflow => overflow,
           :size => font_size,
           :min_font_size => min_font_size,
           :align => text_align})
      else
        texts = [{ text: label_text, styles: [:bold], :size => font_size },  { text: value, :size => font_size }]

        # Label and Content Textbox
        offset = [@orientation[:x_offset], @orientation[:height] - (@orientation[:text_padding] / 2)]
        box = @pdf.formatted_text_box(texts,
          {:height => @orientation[:height],
           :width => @orientation[:width],
           :at => offset,
           :style => font_style,
           :overflow => overflow,
           :min_font_size => min_font_size,
           :align => text_align})
      end

    end

  end
end