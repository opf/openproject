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
      has_label = @config['has_label']
      value = value.to_s if !value.is_a?(String)
      text = ""
      text = text + "#{@work_package.class.human_attribute_name(@property_name)}: " if has_label
      text = text + value

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

      # Draw on pdf
      offset = [@orientation[:x_offset], @orientation[:height] - (@orientation[:text_padding] / 2)]
      box = @pdf.text_box(text,
        {:height => @orientation[:height],
         :width => @orientation[:width],
         :at => offset,
         :style => font_style,
         :overflow => overflow,
         :size => font_size,
         :min_font_size => min_font_size,
         :align => text_align})
    end

  end
end